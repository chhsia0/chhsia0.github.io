---
layout: post
title: 虛擬繼承的邪惡
---

這次的文章，我想來分享的不是現代 C++，而是關於傳統 C++ [虛擬繼承 (virtual inheritance)](https://en.wikipedia.org/wiki/Virtual_inheritance) 的一個小故事。先講結論：能免則免！

前一陣子有個同事在寫某個單元測試的時候，發現了一個很奇怪的現象，於是跑來問我。結果我當下也無法解釋，最後研究了一整個下午之後，我半開玩笑地跑去找另一個同事，說我剛剛設計了一個 C++ 防破台面試題[^you-shall-not-pass]，問他想不想試試看。題目是這樣的：請問下面這段程式碼[^mesos-mock-slave]會印出什麼？
```cpp
#include <iostream>
#include <string>

using namespace std;

class ProcessBase
{
public:
  ProcessBase(const string& id = "foo") : pid(id) {}

  const string pid;
};


template <typename T>
class Process : public virtual ProcessBase {};


class Slave : public Process<Slave>
{
public:
  Slave(const string& id) : ProcessBase(id) {}
};


class MockSlave : public Slave
{
public:
  MockSlave(const string& id) : Slave(id) {}
};


int main()
{
  cout << Slave("bar").pid << endl;
  cout << MockSlave("bar").pid << endl;
  return 0;
}
```

[^you-shall-not-pass]: 在程式競賽中，總會有那麼一題是用來不讓任何一隊拿到滿分的超難題目，戲稱防[破台](https://www.ptt.cc/bbs/ask/M.1250519465.A.599.html)題。
[^mesos-mock-slave]: 這段程式碼是從 [Mesos codebase](https://github.com/apache/mesos/) 中簡化過的程式碼。`Process` 代表一個 [actor](https://en.wikipedia.org/wiki/Actor_model)，`Slave` 代表 Mesos [agent](http://mesos.apache.org/documentation/latest/architecture/)，而 `MockSlave` 自然就是單元測試裡用來模擬指定的 agent 行為的 [mock class](https://en.wikipedia.org/wiki/Mock_object) 了。

同事可能是看到了我邪惡的笑容，仔細端詳了程式碼之後，以下賊上之心的想法說這兩行輸出應該不一樣吧！的確，程式的執行結果如下：
```
bar
foo
```
咦……既然 `MockSlave` 的 constructor 有把 `id` 傳進 `Slave` 的 constructor, `MockSlave("bar")` 和 `Slave("bar")` 不是應該會用一樣的方式初始化各自的 `Slave` 物件嗎？為什麼最後會有不一樣的結果呢？難道我們遇上了某個 C++ 編譯器的 bug，或者難道上面這段程式碼有未定義的行為嗎？

事實上，上面的行為完全符合 [C++ 標準](https://en.cppreference.com/w/cpp/language/initializer_list#Initialization_order)的定義。簡單講，C++ 在初始化物件的時候，有下面幾個步驟：
1. 按 [depth-first traversal](https://en.wikipedia.org/wiki/Tree_traversal#Pre-order_%28NLR%29) 對每一個 [virtual base class](https://en.cppreference.com/w/cpp/language/derived_class#Virtual_base_classes) 初始化*一次*。
2. 依序初始化所有的 direct non-virtual base classes。
3. 依序初始化所有的 non-static 成員變數。
4. 執行當前的 constructor。

之所以有第一步，是因為 C++ 要確保每個 virtual base class 只會被初始化一次，而問題就發生在這裡了：對 `MockSlave` 而言，初始化 `ProcessBase` 是在初始化 `Slave` 之前，而在初始化 `Slave` 的時候才會呼叫 `Slave(id)`。因此，在初始化 `ProcessBase` 的時候，使用的是它的 [default constructor](https://en.cppreference.com/w/cpp/language/default_constructor)，因此 `ProcessBase::pid` 就被設成 `"foo"`，而之後 `Slave(id)` 呼叫的 `ProcessBase(id)` 則會直接被忽略，因為 `ProcessBase` 已經被初始化過了。事實上，如果把 `ProcessBase` 的 constructor 裡面的 `id` 參數的預設值拿掉：
```cpp
ProcessBase(const string& id) : pid(id) {}
```
這樣一來，`ProcessBase` 就沒有了 default constructor，而編譯器會直接報錯[^errors]：
```
error: constructor for 'MockSlave' must explicitly initialize the base class 'ProcessBase' which does not have a default constructor
```

[^errors]: 其實一共會有兩個編譯錯誤，但另一個不是本篇的重點就是了。

所以，如果要正確地初始化 `MockSlave` 的 `ProcessBase`，就得這樣寫：
```cpp
MockSlave(const string& id) : ProcessBase(id), Slave(id) {}
```

眾所周知，虛擬繼承是為了解決多重繼承產生的 [diamond problem](https://en.wikipedia.org/wiki/Multiple_inheritance#The_diamond_problem) 而來的概念。大概是因為虛擬繼承有這些不為人知的眉角，[Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html#Multiple_Inheritance) 才會明定如果要多重繼承，所有的 direct base class 都得是純粹的 interface 而不能帶有成員變數，比方說：
```cpp
class ProcessBase
{
public:
  virtual const string& pid() = 0;
};

...

class Slave : public Process<Slave>
{
public:
  Slave(const string& id) : pid_(id) {}

  const string& pid() override { return pid_; }

private:
  const string pid_;
};
```

至於 Mesos 為什麼會使用虛擬繼承呢？可能 codebase 在某一個時間點曾經出現過吧。不過我也沒仔細找，不知道現在的 codebase 裡還有沒有就是了。總之，如果可以的話，還是儘量不要使用虛擬繼承，以免有人浪費一個下午才搞清楚發生了什麼事😓。

是說，既然把這個防破台題寫在這裡，以後大概沒機會在面試裡出這麼過分的題目了😆。
