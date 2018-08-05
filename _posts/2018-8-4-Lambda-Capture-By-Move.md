---
layout: post
title: Lambda Capture by Move
---

[之前的文章](/When-Rvalue-Met-Reference)稍微提過了用來轉移資料所有權的 [`std::move`](https://en.cppreference.com/w/cpp/utility/move)，這次來聊聊怎樣與 [lambda](https://en.cppreference.com/w/cpp/language/lambda) 搭配服用。對 C++14 及其之後的標準而言，這再簡單不過了：
```cpp
#include <cassert>
#include <functional>
#include <iostream>
#include <memory>
#include <utility>

int main()
{
  std::unique_ptr<int> x(new int(42));
  auto f = [x = std::move(x)](int y) { return *x + y; };

  assert(!x);
  std::cout << f(3) << std::endl;

  return 0;
}
```
這一段程式碼會把 lambda 外面的 `x` 的資料所有權轉移給 lambda 裡面的 `x` (注意 `[x = std::move(x)]` 左手邊的 `x` 指的是 lambda 裡面的 `x`，而右手邊的 `x` 指的是 lambda 外面的 `x`)。雖然之前提到過在經由 `std::move` 轉移所有權之後，存取 lambda 外面 `x` 一般而言屬於未定義的行為，但因為 [`std::unique_ptr` 的 move assignment 運算子](https://en.cppreference.com/w/cpp/memory/unique_ptr/operator%3D)明確定義了在被轉移所有權之後，其內容會變成 [`nullptr`](https://en.cppreference.com/w/cpp/language/nullptr)，所以 `assert(!x)` 不會有任何問題。另外，因為 `f` 有了一個不能被複製的 capture，`f` 本身也不能夠被複製。

如果有 C++14 可以用，那接下來的文章就可以不用看了😛。可惜的是，由於某些因素，我在開發的 [Mesos](https://mesos.apache.org/) 還沒有全面使用 C++14。如果以 C++11 來編譯上面的程式碼，會得到像下面的錯誤訊息：
```
warning: initialized lambda captures are a C++14 extension [-Wc++14-extensions]
  auto f = [x = std::move(x)](int y) {
            ^
```
那麼，在 C++11 裡有什麼替代方案呢？最簡單的當然就是用 [`std::shared_ptr`](https://en.cppreference.com/w/cpp/memory/shared_ptr) 代替 `std::unique_ptr` 了：
```cpp
  std::shared_ptr<int> x(new int(42));
  auto f = [x](int y) { return *x + y; };

  assert(x);
```
雖然這不失為一個可行的方法，但從上面的 `assert(x)` 就可以看到，使用 `std::shared_ptr` 沒有辦法確保 `x` 只能在 `f` 裡面存取。如果程式的正確性倚賴這個前提，這樣寫便顯得有些危險了。即便如此，因為這樣寫起來比下面要講的另一個方法來得易讀，在 [Mesos codebase](https://github.com/apache/mesos/blob/24df6fa1ed8d21c889dfde2efae0b9bc79996815/3rdparty/libprocess/include/process/grpc.hpp#L184-L185) 裡還是有好些地方這樣寫，等到全面用上 C++14 之後再一一改掉。

除了使用 `std::shared_ptr` 之外，其實還有一種方式在 C++11 裡面做到類似 by-move capture 的功能：透過 [`std::bind`](https://en.cppreference.com/w/cpp/utility/functional/bind)！如果對傳統 C++ 比較熟稔的話，可能對 [`std::bind1st`](https://en.cppreference.com/w/cpp/utility/functional/bind12) 和 [`std::bind2nd`](https://en.cppreference.com/w/cpp/utility/functional/bind12) 有點印象。這兩個工具函數的功能是把一個有 _n_ 個參數的函數或 fuction object 的第一個或第二個參數固定住，生成一個 _n_ - 1 個參數的 function object。C++11 拋棄了這兩個工具函數，取而代之的是更加一般化的 `std::bind`，可以任意固定 _k_ 個參數並結合 [placeholders](https://en.cppreference.com/w/cpp/utility/functional/bind12) 生出一個 _n_ - _k_ 個參數的 function object。使用 `std::bind` 實現 by-move capture 的方式如下：
```cpp
  std::unique_ptr<int> x(new int(42));
  auto f = std::bind(
      [](const std::unique_ptr<int>& x, int y) { return *x + y; },
      std::move(x),
      std::placeholders::_1);

  assert(!x);
```
上面這段程式碼中的 lambda 完全沒有任何 capture，而是多宣告了一個新的參數 `x`，然後我們再透過 `std::bind` 把 lambda 外面的 `x` 的資料所有權轉移到生成的 function object 裡面，當作呼叫 lambda 的參數 `x` 使用。如此一來，就可以確保 `x` 只能在 `f` 裡面存取。

不過，雖然 `std::bind` 可以在 C++11 裡實現 by-move capture, 但比起前面的寫法，這樣做還是繁瑣許多。而且 `std::bind` 還有一個小小的問題：它生出來的 function object 和一個普通的 lambda 有些行為不盡相同！不過這要講起來又是一篇文章，所以在這裡先賣個關子，有空再來分享😜。如果可以的話，還是儘快換到 C++14 吧！
