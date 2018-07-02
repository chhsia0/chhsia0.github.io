---
layout: post
title: 當 Rvalue 遇上 Reference
---

在第二篇文章就直衝 [rvalue reference](https://en.cppreference.com/w/cpp/language/reference#Rvalue_references) 這個我覺得自己都還沒完全掌握的概念，實在是個相當大的挑戰。不過既然遲早都會遇上這個概念，不如就試著寫寫看，讓自己更熟悉點。先寫在前面，我並不打算在短短一篇文章裡對 rvalue reference 做全面的介紹，只是分享一些自己對這個概念的理解。有興趣的話，[Dr. Becker 的文章](http://thbecker.net/articles/rvalue_references/section_01.html)算是把 rvalue reference 解釋得相當完整，我當初也是從這篇文章學起的。

C++ 是一個重視程式效能的語言，設計上有不少編譯器後端 (比方說 [code generation](https://en.wikipedia.org/wiki/Code_generation_%28compiler%29) 或是 code optimization) 的考量。因此對編譯器後端和程式運行時資料的儲存空間要有一定的了解，才能把 C++ 學得比較好，而這點對於了解 rvalue reference 特別明顯：rvalue 這個詞，以及對應的 lvalue，都是在 code generation 比較會接觸到的概念，理論上也該從這兩個概念講起，但是……C++ 對於 [rvalue 的定義](https://en.cppreference.com/w/cpp/language/value_category#rvalue)實在是有點難用三言兩語交代清楚😓。所以我在此偷懶一下，直接切入 rvalue reference 的例子。有興趣深入了解的話，可以參考 [Mikael Kilpeläinen 的文章](http://mikael.isocpp.fi/articles/lvalue_and_rvalue.html)。

Rvalue reference 以及它對應的 move semantics 的概念，主要就是減少資料複製以增進程式效能。舉個例子來說[^eg]，假設我們想寫個 [function object](https://en.cppreference.com/w/cpp/utility/functional) 來做向量的[仿射變換](https://zh.wikipedia.org/zh-tw/%E4%BB%BF%E5%B0%84%E8%AE%8A%E6%8F%9B)：
```cpp
template <int N>
class AffineTransformer
{
public:
  AffineTransformer(const Matrix<N, N>& _matrix, const Matrix<N, 1>& _shift)
    : matrix(_matrix), shift(_shift) {}

  Matrix<N, 1> operator()(const Matrix<N, 1>& vec)
  {
    return matrix * vec + shift;
  }

private:
  const Matrix<N, N> matrix;
  const Matrix<N, 1> shift;
};
```
如果想產生一個隨機的仿射變換，我們可以先隨機生成一個矩陣和向量，然後把它們傳進 `AffineTransformer` 的 constructor：
```cpp
Matrix<1024, 1024> randomMatrix = Matrix<1024, 1024>::random();
Matrix<1024, 1> randomShift = Matrix<1024, 1>::random();
AffineTransformer<1024> transform(randomMatrix, randomShift);
```
因為 `AffineTransformer` 的 constructor 會複製傳入的 `_matrix` 和 `_shift`，如果這個變換的維度很大，複製矩陣和向量會很花時間。而且大部份的情況下，一旦生成 `transform` 這個 function object 之後，`randomMatrix` 和 `randomShift` 這兩個變數就沒用了。如果能讓 `transform` 直接「擁有」`randomMatrix` 和 `randomShift` 的資料，不就可以避免資料複製嗎？因此，C++11 引入了 rvalue reference 和 [move constructor](https://en.cppreference.com/w/cpp/language/move_constructor) 來實現這個想法：首先，假設 `Matrix` 有 move constructor：
```cpp
template <int M, int N>
class Matrix
{
public:
  // Default constructor.
  Matrix() : data(new double[M][N]) {}

  // Copy constructor.
  Matrix(const Matrix& matrix) : data(new double[M][N])
  {
    memcpy(data, matrix.data, M * N * sizeof(double));
  }

  // Move constructor.
  Matrix(Matrix&& matrix)
  {
    data = matrix.data;
    matrix.data = nullptr;
  }

  // Destructor.
  ~Matrix()
  {
    // NOTE: It is safe to delete a null pointer.
    delete[] data;
  }

private:
  double (*data)[N];
};
```
其中 `Matrix&&` 就是代表一個 `Matrix` 的 rvalue reference。值得一提的是，`&&` 除了代表 rvalue reference 之外，也用來表示 [forwarding reference](https://en.cppreference.com/w/cpp/language/reference#Forwarding_references)——用來實現 perfect forwarding 的另一個概念。不過且容我在此按下不表，咱們日後再提。

有了 `Matrix` 的 move constructor 之後，我們就可以把 `AffineTransformer` 的 constructor 參數改用 rvalue reference：
```cpp
template <int N>
class AffineTransformer
{
  ...

  AffineTransformer(Matrix<N, N>&& _matrix, Matrix<N, 1>&& _shift)
    : matrix(_matrix), shift(_shift) {}

  ...
};
```
接著在生成隨機變換的時候使用 [`std::move`](https://en.cppreference.com/w/cpp/utility/move) 來轉移 `randomMatrix` 和 `randomShift` 的資料所有權：
```cpp
AffineTransformer<1024> transform(
    std::move(randomMatrix), std::move(randomShift));
```
`std::move(randomMatrix)` 和 `std::move(randomShift)` 分別會傳回變數 `randomMatrix` 以及 `randomShift` 的 `Matrix` rvalue，而且值得注意的是，這兩個變數會處於「不可存取但可以解構」的狀態，也就是說之後對兩個變數而言，除了呼叫 destructor 之外，其他動作都屬於未定義的行為。因此 `Matrix` 的 destructor 也必須要能解構一個「資料所有權已經被移走」的 `Matrix` 物件。

[^eg]: 本來想參考個網路上的例子，但看了一兩個例子的設定都不是很自然，比方說藉由對變數重複賦值來強調 move semantics。但是我覺得好的程式風格似乎不常遇到這樣的寫法，所以只好自己生一個了。

在上面的例子裡，把 `AffineTransformer` 的 constructor 參數宣告為 rvalue reference 以及使用 move semantics 雖然可以避免資料複製，但也產生了新的限制：生成 `AffineTransformer` 的時候，一定要轉移傳入資料的所有權。雖然大部份情況這個限制不是大問題，但如果遇之後還要用到 `randomMatrix` 的情況，就得手動複製一份資料出來，很是麻煩。不過這倒是不難解決；我們可以把 `AffineTransformer` 的 constructor 再度改寫成下面這個樣子：
```cpp
template <int N>
class AffineTransformer
{
  ...

  AffineTransformer(Matrix<N, N> _matrix, Matrix<N, 1> _shift)
    : matrix(std::move(_matrix)), shift(std::move(_shift)) {}

  ...
};
```
咦……怎麼把參數改用 pass-by-value 的形式宣告了？這不是會產生額外的資料複製嗎？其實不一定：
```cpp
// `randomMatrix` and `randomShift` are copied, so they can still be used later.
AffineTransformer<1024> transform1(randomMatrix, randomShift);

// `randomMatrix` and `randomShift` are moved, so they cannot be used anymore.
AffineTransformer<1024> transform2(
    std::move(randomMatrix), std::move(randomShift));
```
在這個例子裡，生成 `transform1` 的時候會複製傳入的資料，因此 `randomMatrix` 和 `randomShift` 還可以繼續使用。但生成 `transform2` 的時候，這兩個變數的資料所有權會被轉移，用以初始化 `AffineTransformer` constructor 的 `_matrix` 和 `_shift` 參數，然後它們的資料所有權會再度被轉移，用以初始化 `AffineTransformer` 的 `matrix` 和 `shift` 這兩個成員變數。因此在現代 C++ 裡，即使參數宣告成 pass-by-value 的形式，也不代表傳入的資料一定會被複製——有可能其實只是所有權轉移！
