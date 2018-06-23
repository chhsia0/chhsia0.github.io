---
layout: post
title: 楔子；行話
---

上次認真地學 C++ 大概是在 2002 年了吧！那時候啃了本 [The C++ Standard Library](http://www.josuttis.com/libbook/) 中文版，是本基於 C++98 寫的書。之後雖然還算常寫 C++，但一直懶得去研究新的 C++ 標準多了什麼，只有偶爾學到一點點零散的小東西，也不太常去用。直到去年開始參與開發 [Apache Mesos](https://mesos.apache.org/)，才大量接觸到以「現代」C++ 編寫的程式碼 (這裡指的是 C++11，其實也是兩代以前的標準了)。套個棋靈王的哏，這感覺就像是本因坊秀策……旁邊的倒茶小弟在學習現代定石吧😆！

這一年多以來，也從幾個厲害的同事學了不少現代 C++ 的寫法和技巧，所以興起了找個地方記錄下來的念頭。另外，自從不太用 [Ptt2](ssh://bbs@ptt2.cc) 之後，其實也是有想過弄個網誌隨意分享些東西，只不過之前一直因為沒有一個明確的想法而疏懶於實行。既然現在有個主題，總算有興頭研究有哪些網誌平台可以選擇，還有要怎麼自訂各種細節打造出自己的網誌，結果研究了一堆有的沒的，弄了快一個月才開始寫第一篇文章😅。不過我也沒有特別想把這個網誌定位為技術導向，只是把 C++ 當作一個開始，畢竟覺得我對非正式的技術文章比較容易發揮。以後有其他想分享的主題，再慢慢拓展這個網誌的範圍囉。

既然這是第一篇文章，先來分享一個輕鬆的主題—— C++ 的「行話」。每個領域都有它特定的術語，而知道這些術語才能偽裝成這個領或的專家😉，C++ 當然也不例外 (雖然我是不建議大家自稱 C++ 專家就是了)。比方說，在講到一些跟定義變數、函數或是初始化有關的語法規則的時候，講「.cpp 檔」聽起來就沒那麼專業，而講 [translation unit](https://en.wikipedia.org/wiki/Translation_unit_%28programming%29) (大致上指的是一份完整的、前置處理完畢之後一次餵給 C++ 編譯器的內容) 就顯得專業多了！這個詞其實在爬 C++ 文獻，例如 [ODR](https://en.cppreference.com/w/cpp/language/definition) 的時候很常看到，所以會講 translation unit 表示至少你會去看一些 C++ 文件😏。

C++ 的行話有個特點是很喜歡用縮寫，比方說上面提到的 ODR (One Definition Rule)，另外還有 [POD](https://en.cppreference.com/w/cpp/named_req/PODType) (Plain Old Data) 和 [ADL](https://en.cppreference.com/w/cpp/language/adl) (Argument-Dependent Lookup) 等等，以及我個人覺得最幽默的 [SFINAE](https://en.cppreference.com/w/cpp/language/sfinae) (Substitution Failure Is Not An Error)。SFINAE 是現代 C++ 的 template 語法裡的重要概念，而這樣縮寫起來又讓這個概念聽起來更加高深莫測了些。之後再寫幾篇文章分享我對 SFINAE 和 ODR 的心得。

如果想假裝自己是 C++ 的專家，光是知道這些行話還不夠，還得知道要怎麼念這些詞彙，侃侃而談起來才有專業感。下面這些都是我從強者我前同事 [MPark](https://mpark.github.io/about/) 學來的念法，來分享一下身為 C++ 標準委員會的人是怎麼講一些常見的詞：
* SFINAE：這比較沒什麼特別，就直接照拼法發音成 s-fi-nay，別一個字母一個字母念就是了。
* `std`：大家猜猜看這怎麼念？S-T-D？standard？不不不，專業點的念法是 st<sup>ə</sup>d 但 ə 的音很輕。第一次聽到的時候其實覺得挺神奇的。
* `ptr`：跟 `std` 很類似，前同事會念成 p<sup>ə</sup>&apos;ter。所以 `std::shared_ptr` 就變成了 st<sup>ə</sup>d-shared-p<sup>ə</sup>&apos;ter。

不過這些發音其實也不是絕對的，只是些個人偏好罷了。在寫這篇文章的時候順手查到了一篇 [Reddit 上的討論](https://www.reddit.com/r/cpp/comments/3gxu2b/discussion_how_do_you_pronounce/)，有興趣的話可以看看有哪些不同的念法。

雖然上面分享了如何說得一口好 C++，但我覺得說自己精通 C++ 是件危險的事，畢竟 C++ 有太多眉角了。如果真的很懂，就譲履歷自己說話吧！
