// 手冊：從 ESKF 到不變誤差與切群濾波器（繁體中文版，與英文版逐段對應）
#let vsp = v
#set page(paper: "a4", margin: (x: 2.1cm, y: 2.2cm), numbering: "1", header: context {
  if counter(page).get().first() > 1 [
    #set text(size: 8.5pt, fill: luma(110))
    從 ESKF 到不變誤差與切群濾波器 — 審閱稿 3
    #h(1fr) kf-toy 教學手冊
  ]
})
#set text(font: ("Libertinus Serif", "Noto Sans CJK TC"), size: 10.5pt, lang: "zh", region: "TW")
#set par(justify: true, leading: 0.68em)
#set heading(numbering: "1.1", supplement: [第])
#show heading.where(level: 1): it => { vsp(14pt); text(size: 17pt, it); vsp(6pt) }
#show heading.where(level: 2): it => { vsp(8pt); text(size: 12.5pt, it); vsp(3pt) }
#set math.mat(delim: "[")
#set math.vec(delim: "[")
#set math.equation(numbering: "(1)", supplement: [式])
#set figure(supplement: [圖])
#show math.equation: set text(font: ("New Computer Modern Math", "Noto Sans CJK TC"))
#show raw.where(block: false): it => box(fill: luma(240), inset: (x: 2.5pt, y: 0pt), outset: (y: 2.5pt), radius: 2pt, it)
#show raw.where(block: true): it => block(fill: luma(245), inset: 7pt, radius: 3pt, width: 100%, text(size: 8.6pt, it))
#show figure.caption: it => { set text(size: 9pt); it }
#show link: underline
#show ref: it => {
  let el = it.element
  if el != none and el.func() == heading and el.numbering != none {
    let n = counter(heading).at(el.location())
    let label = if type(el.numbering) == function {
      if n.len() == 1 { "附錄 " + numbering("A", n.at(0)) } else { numbering("A.1", ..n) }
    } else {
      if n.len() == 1 { "第 " + str(n.at(0)) + " 章" } else { "第 " + numbering("1.1", ..n) + " 節" }
    }
    link(el.location(), text(fill: rgb("#1f4e9c"), label))
  } else {
    text(fill: rgb("#1f4e9c"), it)
  }
}

#let note(title, body) = block(width: 100%, inset: 9pt, radius: 3pt, fill: rgb("#eef3fb"), stroke: (left: 2.5pt + rgb("#2455a4")))[
  #text(weight: "bold", title) \ #body ]
#let warn(title, body) = block(width: 100%, inset: 9pt, radius: 3pt, fill: rgb("#fdf3e7"), stroke: (left: 2.5pt + rgb("#df741a")))[
  #text(weight: "bold", title) \ #body ]
#let oneline(body) = block(width: 100%, inset: 9pt, radius: 3pt, fill: rgb("#eef7f1"), stroke: (left: 2.5pt + rgb("#278566")))[
  #text(weight: "bold")[一句話總結] \ #body ]
#let fig(path, cap, w: 100%) = figure(image("fig/" + path, width: w), caption: cap)
#let two(a, b) = grid(columns: (1fr, 1fr), gutter: 8pt, a, b)
#let zh(body) = text(font: "Noto Sans CJK TC", body)

// 簡寫（除上面已另名的 v 之外，不覆蓋 Typst 內建）
#let R = $bold(R)$
#let Rh = $hat(bold(R))$
#let v = $bold(v)$
#let p = $bold(p)$
#let g = $bold(g)$
#let I3 = $bold(I)_3$
#let I = $bold(I)$
#let w = $bold(omega)$
#let a = $bold(a)$
#let bg = $bold(b)_g$
#let ba = $bold(b)_a$
#let bnu = $bold(b)_nu$
#let dth = $delta bold(theta)$
#let hx(x) = $[#x]_times$

// ---------------------------------------------------------------- 標題
#vsp(0.6cm)
#align(center)[
  #text(size: 24pt, weight: "bold")[從 ESKF 到不變誤差與 \ 切群濾波器]
  #vsp(6pt)
  #text(size: 13pt)[以矩陣形式撰寫的手冊，並以 `kf-toy` 教學範例佐證]
  #vsp(10pt)
  #text(size: 10pt, fill: luma(90))[審閱稿 3 — 圖表由 `results/teaching` 產生（4 個種子、12 s、`kf_teaching-v2`）]
]
#vsp(0.4cm)

#heading(numbering: none)[本手冊涵蓋的內容]

本手冊以同一個估測問題——IMU 傳遞加上載體速度與航向修正——依序走過五種表述。每一步只改動少數幾個矩陣，濾波器的其餘部分維持不變；每一章只列出被改動的矩陣，接著用教學範例的圖表把改動的效果顯示出來。任何一章都不依賴之後的章節。

*為什麼要一階一階走，而不是一步跳到終點。* 終點是切群（tangent group）上的等變濾波器（equivariant filter），它與教科書上的 ESKF 同時在四個彼此獨立的面向上不同：IMU 如何積分、誤差如何定義、偏差如何參數化、狀態有多大。若只做一次兩者的 A/B 比較，無法分辨指標上的差異來自這四者中的哪一個。因此本手冊把各個配方（recipe）排成階梯，每一階只改動其中一項、保留先前的選擇；而範例中的等價測試證實每一階沒有改動其他東西（例如 Step3 與縮減版切群濾波器 C15A 在 $10^(-8)$ 內完全一致）。右不變誤差那一章既是一個可獨立使用的濾波器——即固定重力的不變 EKF，可直接當作「不變 ESKF」使用——也是缺了它、切群那一章就得同時改動三件事的關鍵一階。

#text(size: 9pt)[#table(columns: (0.95fr, 0.7fr, 1.4fr, 1.25fr, 1.4fr, 0.45fr), inset: 4.5pt, stroke: 0.4pt + luma(170), align: (left, left, left, left, left, center),
  [*階段*], [*配方*], [*新增內容*], [*這一階唯一隔離的變因*], [*範例顯示什麼*], [*章*],
  [ESKF], [Step1], [名義流、誤差向量、$bold(F)$、$bold(Q)$、Joseph 更新、重置], [—（基準）], [模型相符時，基準濾波器是一致的], [#link(<ch:eskf>)[1]],
  [ESKF + 伽利略流], [Step2], [單一矩陣指數取代 Euler；$bold(F)$ 中出現 $Gamma$ 區塊], [IMU 積分公式；誤差定義不變], [保持輸入下精確；輸入取樣成為剩餘誤差], [#link(<ch:gal>)[2]],
  [不變誤差狀態], [Step3, Step4], [擴展位姿上的右不變誤差；物理 Jacobian 與重置 Jacobian], [誤差定義（Step3），再來是偏差參數化（Step4）；流不變], [傳遞不再依賴姿態估測值], [#link(<ch:inv>)[3]],
  [切群上的 EqF], [Step5A, C15A \ Step5B, C15B], [含虛擬部分的 9 維偏差；約束處理；中點輸出], [以 $bnu$ 擴展狀態（5A 對 Step4）；僅改一列輸出（B 對 A）], [常數耦合；如何把 $bnu$ 保持為零；改一列輸出會改變什麼], [#link(<ch:tg>)[4], #link(<ch:cstar>)[5]],
  [迭代求解器], [GN, LM \ 適用所有配方], [固定先驗的 MAP；KF 即第一步 Gauss–Newton], [線性化次數；先驗、概似與座標卡不變], [大誤差回復；迭代下輸出變體趨於一致], [#link(<ch:gnlm>)[6]],
  [結語], [—], [模型失配下的診斷], [模型，而非幾何], [NEES 與覆蓋率能揭露 cost 與 NIS 看不見的問題], [#link(<ch:diag>)[7]])]

符號、運算子 $hx(dot)$、$Gamma_1, Gamma_2$、$op("Ad"), op("ad")$、所有分數共用的物理誤差座標卡，以及共同實驗設定，都整理在 @app:common，並在首次使用處加上連結。兩個約定貫穿全文：$t$ 是時間，$h$ 是一個傳遞區間的長度；帶帽符號表示估測值，不帶帽表示真值。

#pagebreak()
#[
  #set text(size: 9.4pt)
  #show outline.entry: set block(above: 0.62em)
  #show heading: set block(below: 0.6em)
  #outline(title: [目錄], indent: auto, depth: 2)
]
#pagebreak()

// ---------------------------------------------------------------- 1
= 誤差狀態卡爾曼濾波器（Step1） <ch:eskf>

狀態為 $(R, v, p, bg, ba)$，IMU 模型見 @app:state；反對稱矩陣 $hx(dot)$ 與級數 $Gamma_1, Gamma_2$ 定義於 @app:ops。本章寫下之後每一章都會修改的五個矩陣。

== 保持輸入下的名義傳遞

在長度為 $h$ 的一個區間內，使用區間內保持、且已扣除偏差的輸入 $w = tilde(w) - hat(bg)$、$a = tilde(a) - hat(ba)$，Euler ESKF 的傳遞為
$ mat(R^+; v^+; p^+; bg^+; ba^+) = mat(
  R exp(h hx(w));
  v + h g + h R a;
  p + h v + 1/2 h^2 g + 1/2 h^2 R a;
  bg;
  ba). $ <eq:step1flow>

== 誤差定義：載體座標系姿態，其餘皆為加法

真值狀態是估測值被 15 維向量 $delta bold(x) = (dth, delta v, delta p, delta bg, delta ba)$ 擾動後的結果：
$ mat(R; v; p; bg; ba) = mat(
  Rh exp(hx(dth));
  hat(v) + delta v;
  hat(p) + delta p;
  hat(bg) + delta bg;
  hat(ba) + delta ba). $ <eq:leftchart>
這是*左*（載體座標系）擾動。它與所有分數使用的物理誤差向量（@app:yardstick）相同，因此 Step1 在計分前不需要任何座標轉換。

== 離散轉移與程序雜訊

在 @eq:leftchart 的座標下把 @eq:step1flow 線性化：
$ bold(F)_"Step1" = mat(
  exp(-h hx(w)), 0, 0, -h Gamma_1(-h w), 0;
  -h Rh hx(a), I3, 0, 0, -h Rh;
  -1/2 h^2 Rh hx(a), h I3, I3, 0, -1/2 h^2 Rh;
  0, 0, 0, I3, 0;
  0, 0, 0, 0, I3). $ <eq:F1>
連續白雜訊 $bold(n) = (bold(n)_g, bold(n)_a, bold(n)_(b g), bold(n)_(b a))$ 經由
$ bold(G) = mat(-I3, 0, 0, 0; 0, -Rh, 0, 0; 0, 0, 0, 0; 0, 0, I3, 0; 0, 0, 0, I3), wide
  bold(Q)_c = mat(sigma_g^2 I3, 0, 0, 0; 0, sigma_a^2 I3, 0, 0; 0, 0, sigma_(b g)^2 I3, 0; 0, 0, 0, sigma_(b a)^2 I3), $ <eq:G1>
進入系統，而離散程序共變異數把在時刻 $t in [0, h]$ 注入的雜訊搬運到區間末端：
$ bold(Q) = integral_0^h bold(Phi)(h, t) bold(G)(t) bold(Q)_c bold(G)(t)^top bold(Phi)(h, t)^top dif t . $ <eq:Q>
範例以三點 Gauss 求積計算 @eq:Q；測試將其與積分白加速度的解析結果比對：
$ mat(bold(Q)_(v v), bold(Q)_(v p); bold(Q)_(p v), bold(Q)_(p p)) = sigma_a^2 mat(h I3, 1/2 h^2 I3; 1/2 h^2 I3, 1/3 h^3 I3). $
引擎從不顯式計算 $bold(F) bold(P) bold(F)^top + bold(Q)$。它維護平方根 $bold(L)$，$bold(P) = bold(L) bold(L)^top$，並壓縮
$ mat(bold(F) bold(L), bold(N)) arrow.r.long^"QR" bold(L)^+, wide bold(N) bold(N)^top = bold(Q), $ <eq:sqrt>
因此半正定性在結構上就獲得保證。

== 量測更新與重置

對殘差 $bold(r) = bold(z) - bold(y)(hat(bold(x)))$，其中預測量測為 $bold(y)$、Jacobian 為 $bold(H)$、雜訊為 $bold(V)$：
$ mat(bold(S); bold(K); delta bold(x); bold(P)') = mat(
  bold(H) bold(P) bold(H)^top + bold(V);
  bold(P) bold(H)^top bold(S)^(-1);
  bold(K) bold(r);
  (I - bold(K) bold(H)) bold(P) (I - bold(K) bold(H))^top + bold(K) bold(V) bold(K)^top). $ <eq:joseph>
修正量以 @eq:leftchart 收回（retract）到名義狀態。由於姿態誤差是繞著*舊*估測值定義的，共變異數必須搬運到新估測值上：
$ bold(P)^+ = bold(J) bold(P)' bold(J)^top, wide
  bold(J)_"exact" = mat(bold(J)_r (dth), 0; 0, bold(I)_12), quad
  bold(J)_"1st" = mat(I3 - 1/2 hx(dth), 0; 0, bold(I)_12), quad
  bold(J)_"textbook" = bold(I)_15, $ <eq:reset>
其中 $bold(J)_r (dth) = Gamma_1(-dth)$ 是 SO(3) 的右 Jacobian。範例中的所有配方都使用精確形式；一階近似的誤差大小繪於 @ch:gal。

== 此座標卡下的量測 Jacobian

令 $hat(v)_B = Rh^top hat(v)$ 為預測的載體速度、$bold(l)$ 為槓桿臂、$bold(h)_theta$ 為安裝 x 軸的偏航角對 $dth$ 的導數：
$ mat(bold(H)_"vel"; bold(H)_"pos"; bold(H)_"yaw") = mat(
  hx(hat(v)_B), Rh^top, 0, 0, 0;
  -Rh hx(bold(l)), 0, I3, 0, 0;
  bold(h)_theta^top, 0, 0, 0, 0). $ <eq:H1>

== 範例中的 Step1

基準情境是 `matched_heading`（@app:experiment）：固定偏差、雜訊相符、每 0.2 s 一次航向量測。

#note("如何解讀 NEES、NIS 與覆蓋率")[
  濾波器除了回報估測值，也回報誤差共變異數 $bold(P)$；問題在於 $bold(P)$ 是否誠實。*正規化估測誤差平方*（normalized estimation error squared）把真實誤差（在範例中可取得）與該共變異數相比，
  $ op("NEES")_15 = bold(e)^top bold(P)_"phys"^(-1) bold(e), $
  其中 $bold(e)$ 是 @app:yardstick 定義的 15 維物理誤差。若誤差為共變異數 $bold(P)$ 的高斯分布，則 $op("NEES")_15$ 服從 15 個自由度的 $chi^2$ 分布、平均值為 15；範例回報的是其時間平均除以 15，因此*一致*（consistent）的濾波器會落在 1 附近，大於 1 表示濾波器*過度自信*（其 $bold(P)$ 相對實際誤差太小），小於 1 表示*保守*。NEES 完全不說明誤差有多小——一個濾波器可以 RMSE 很低而 NEES 為 70，也可以 RMSE 很高而 NEES 為 1。*正規化創新平方*（normalized innovation squared）是同一構造套用在量測殘差上，$op("NIS") = bold(r)^top bold(S)^(-1) bold(r)$，$bold(S)$ 取自 @eq:joseph；它不需要真值，對 3 維速度的平均值為 3，但它只看得到量測看得到的部分。*覆蓋率*（coverage）是某一分量的真實誤差落在其 $plus.minus 1.96 sigma$ 區間內的時間比例；理想值為 0.95。時間樣本彼此相關，因此這些都是診斷指標，而非顯著性檢定。
]
#two(fig("c1_matched_pos.svg", [Step1 KF 位置誤差，種子 0。誤差維持在速度雜訊與先驗所決定的 0.1–0.3 m 水準。]),
     fig("c1_matched_nees.svg", [Step1 KF 的 NEES15/15 隨時間變化，種子 0。它在 1 附近波動；四個種子的平均為 0.954。]))
四個種子的平均，Step1 KF：位置 RMSE 0.179 m、姿態 RMSE 0.0162 rad、NEES15/15 0.954、速度 NIS 2.90（3 個自由度）。

#oneline[
  ESKF 就是五個矩陣：流 @eq:step1flow、座標卡 @eq:leftchart、轉移 @eq:F1 與雜訊 @eq:G1–@eq:Q、更新 @eq:joseph、重置 @eq:reset。當雜訊與模型和資料相符時，它是一致的（NEES ≈ 1、NIS ≈ 3）。
]

// ---------------------------------------------------------------- 2
= 使用伽利略流的 ESKF（Step2） <ch:gal>

Step2 保留座標卡 @eq:leftchart、更新 @eq:joseph 與重置 @eq:reset。它取代了流 @eq:step1flow，因此也取代了轉移 @eq:F1。把導航狀態寫成單一矩陣，就能看出新的流為何是精確的。

== 把導航狀態寫成矩陣

$ bold(X) = mat(R, v, p; 0, 1, 0; 0, 0, 1) in "SE"_2(3) subset RR^(5 times 5), wide
  bold(X)_1 bold(X)_2 = mat(R_1 R_2, R_1 v_2 + v_1, R_1 p_2 + p_1; 0, 1, 0; 0, 0, 1). $ <eq:se23>
乘積把旋轉複合起來，並搬運兩個向量。伽利略群 $"SGal"(3)$ 在 $(2,3)$ 位置多了一個時間項；正是這一項使得速度能在單一指數內耦合進位置。

== 保持的 IMU 輸入就是單一矩陣指數

把保持的載體輸入放進一個時間變化率為單位值的矩陣：
$ bold(W) = mat(hx(w), a, 0; 0, 0, 1; 0, 0, 0), wide
  exp(h bold(W)) = mat(exp(h hx(w)), h Gamma_1(h w) a, h^2 Gamma_2(h w) a; 0, 1, h; 0, 0, 1). $ <eq:galexp>
封閉形式來自於 $bold(W)^k$ 的速度欄為 $hx(w)^(k-1) a$、位置欄為 $hx(w)^(k-2) a$；乘上 $1 \/ k!$ 求和後恰好得到 @app:ops 的 $Gamma$ 級數。把重力當作左因子，作用在區間起點時間項為零的狀態上，
$ bold(X)^+ = underbrace(mat(I3, h g, -1/2 h^2 g; 0, 1, 0; 0, 0, 1), #zh[重力]) space bold(X) space underbrace(exp(h bold(W)), #zh[保持的載體輸入]), $ <eq:galstep>
展開即得 Step2 的流
$ mat(R^+; v^+; p^+; bg^+; ba^+) = mat(
  R exp(h hx(w));
  v + h g + h R Gamma_1(h w) a;
  p + h v + 1/2 h^2 g + h^2 R Gamma_2(h w) a;
  bg;
  ba). $ <eq:step2flow>
與 @eq:step1flow 對照：Euler 只保留每個級數的 $k = 0$ 項，$Gamma_1 approx I3$、$Gamma_2 approx 1/2 I3$。對區間內為常數的載體輸入，@eq:step2flow 對任意 $h$ 都精確；數學測試在 $h = 0.5 "s"$、$omega_z = 2 "rad/s"$、$f_x = 3 "m/s"^2$ 下驗證此事。

== 轉移矩陣多出偏差敏感度區塊

在同一座標卡下對 @eq:step2flow 微分：
$ bold(F)_"Step2" = mat(
  exp(-h hx(w)), 0, 0, -h Gamma_1(-h w), 0;
  -Rh hx(h Gamma_1 a), I3, 0, -h^2 Rh bold(D)_1, -h Rh Gamma_1;
  -Rh hx(h^2 Gamma_2 a), h I3, I3, -h^3 Rh bold(D)_2, -h^2 Rh Gamma_2;
  0, 0, 0, I3, 0;
  0, 0, 0, 0, I3), wide
  bold(D)_i = (partial (Gamma_i (bold(phi)) a)) / (partial bold(phi)) |_(bold(phi) = h w). $ <eq:F2>
相對於 @eq:F1 有兩個區塊改變：加速度計偏差那一欄改以 $Gamma_1, Gamma_2$ 旋轉而非 $I3, 1/2 I3$；陀螺儀偏差那一欄現在經由 $bold(D)_1, bold(D)_2$ 影響到速度與位置（陀螺儀偏差會讓積分後的加速度傾斜）。$bold(G)$ 與 @eq:Q 不變。

== 精確性買到了什麼、沒買到什麼

#two(fig("integration_held.svg", [以 2 rad/s 旋轉的常數載體力，積分 1 s。Step2 在每個步長下都精確（下限為捨入誤差）；Step1 以一階收斂。]),
     fig("integration_varying.svg", [載體力為 $3 cos 1.7 t$。兩個配方現在都帶有輸入取樣誤差。保持*中點*樣本可讓 Step2 以二階收斂；保持左端樣本則不行。]))
一旦真實訊號在樣本之間變化，瓶頸就不再是積分公式，而是對區間內輸入的描述。把精確的 ZOH 套用在錯誤的樣本上，仍然只有一階。

#fig("so3.svg", [加法式旋轉近似對角度的誤差。$I + hx(bold(phi))$ 以二次方失去正交性；一階重置 $I - 1/2 hx(bold(phi))$ 以三次方偏離 $bold(J)_r$，從 0.1 rad 起就看得見；$exp$ 保持正交至機器精度。], w: 70%)

在 40 Hz 的範例情境下，兩個配方無法區分（KF，四個種子平均）：`matched_heading` 0.179 對 0.181 m、`pure_dr` 0.962 對 0.963 m、NEES15/15 0.954 對 0.953。差異存在於步長掃描之中。

#oneline[
  Step2 = Step1，但流換成單一指數 @eq:galexp–@eq:galstep、轉移換成 @eq:F2。誤差定義不動。
]

// ---------------------------------------------------------------- 3
= 不變誤差狀態（Step3、Step4） <ch:inv>

== 為什麼是這一步，為什麼是現在

@ch:gal 改變了 IMU 的積分方式，而不動誤差定義 @eq:leftchart。本章反過來：保留 Step2 的流，只改變 15 維向量 $delta bold(x)$ 的*意義*。有兩個理由說明這一階本身就值得存在，還有一個理由說明它為何放在這個位置。

作為濾波器，結果就是固定重力的右不變 EKF——常被稱為不變 ESKF。它的賣點直接寫在矩陣裡：誤差動態的姿態列與速度列不再依賴姿態估測值（見下文 @eq:Ainv），因此錯誤的姿態不會污染自身的傳遞。這個性質正是 `pure_dr` 情境設計來探測的。

作為階梯的一階，Step3 就是 @ch:tg 的切群濾波器拿掉虛擬偏差的結果；範例以 Step3 與 C15A 在 $10^(-8)$ 內一致來證明這一點。若手冊從 Step2 直接跳到 Step5A，比較時會同時改動誤差定義、偏差參數化與狀態維度，任何指標都無法歸因於其中任何一項。Step3 隔離誤差定義；Step4 接著隔離偏差參數化；@ch:tg 隔離狀態擴展。

改變 $delta bold(x)$ 的意義會迫使我們回答三個 ESKF 從不需要問的記帳問題，因為在左座標卡下它們的答案都很平凡（恆等或近乎恆等）。這三個問題先在 @sec:retract–@sec:reset 回答，使 @sec:rinv 的不變誤差可以立即使用。

== Retract 與 local <sec:retract>

*為什麼需要。* 卡爾曼更新 @eq:joseph 產生的是一個*向量* $delta bold(x)$；估測器的狀態卻是一個旋轉矩陣加四個向量。必須有東西把向量變成狀態（以套用修正），也必須有東西把兩個狀態變成一個向量（以計算計分用的誤差 $bold(e)$、之後執行 GN/LM、以及用有限差分檢查 Jacobian）。在 ESKF 裡這就是 @eq:leftchart，只是從未被命名。一旦允許向量代表別的意義，這兩個映射就必須明確寫下，而濾波器裡的其他每一個矩陣都是它們的導數。

座標卡（chart）是狀態與向量之間一對互逆的映射，$bold(x) = op("retract")(hat(bold(x)), delta)$ 與 $delta = op("local")(hat(bold(x)), bold(x))$。@eq:leftchart 是左座標卡。*右不變*座標卡則從左側乘上 5×5 矩陣 @eq:se23：
$ bold(X) = exp(bold(xi)^and) hat(bold(X)), wide
  bold(xi)^and = mat(hx(bold(xi)_theta), bold(xi)_v, bold(xi)_p; 0, 0, 0; 0, 0, 0), wide
  exp(bold(xi)^and) = mat(bold(E), Gamma_1(bold(xi)_theta) bold(xi)_v, Gamma_1(bold(xi)_theta) bold(xi)_p; 0, 1, 0; 0, 0, 1), $ <eq:rightchart>
其中 $bold(E) = exp(hx(bold(xi)_theta))$，因此
$ mat(R; v; p; bg; ba) = mat(
  bold(E) Rh;
  bold(E) hat(v) + Gamma_1(bold(xi)_theta) bold(xi)_v;
  bold(E) hat(p) + Gamma_1(bold(xi)_theta) bold(xi)_p;
  hat(bg) + delta bg;
  hat(ba) + delta ba). $ <eq:rightretract>
Step3 中偏差仍為加法；Step4 也會改動偏差（@eq:step4bias）。

== 物理 Jacobian

*為什麼需要。* 座標卡改變後，Step3 共變異數的元素 $P_(4 4)$ 不再是 @app:yardstick 意義下的「x 向速度誤差的變異數」：原生座標 $bold(xi)_v$ 把速度與估測值的世界座標系旋轉混在一起。要拿 Step3 與 Step1 比較、對同一真值計算 NEES、或畫出 z 位置的 $plus.minus 1.96 sigma$ 區間，都必須先把共變異數搬到同一個約定好的座標卡。沒有這個矩陣，各配方會以不同的單位計分，任何排名都沒有意義。

原生共變異數 $bold(P)$ 現在活在 $bold(xi)$ 座標中，而所有分數都活在物理座標卡（@app:yardstick）。一階下 $delta bold(x) = bold(J)_"phys" bold(xi)$，其中
$ bold(J)_"phys" = mat(
  Rh^top, 0, 0, 0, 0;
  -hx(hat(v)), I3, 0, 0, 0;
  -hx(hat(p)), 0, I3, 0, 0;
  0, 0, 0, I3, 0;
  0, 0, 0, 0, I3), wide
  bold(P)_"phys" = bold(J)_"phys" bold(P) bold(J)_"phys"^top. $ <eq:Jphys>
$Rh^top$ 區塊說的是：世界座標系的旋轉擾動等於載體座標系的擾動再轉回去；$-hx(hat(v))$、$-hx(hat(p))$ 區塊說的是：世界座標系的旋轉也會移動速度與位置。在此座標卡下對角的原生 $bold(P)$，對應到的是*有相關性*的物理共變異數。數學測試對所有配方以中央有限差分檢查 @eq:Jphys。

== 重置 Jacobian <sec:reset>

*為什麼需要。* 更新前的共變異數描述的是*繞著舊估測值*的擾動。更新把估測值移動了一個有限的 $delta$；切空間跟著移動，舊估測值的擾動與新估測值上同樣大小的擾動不是同一個向量。對左座標卡而言，差異只出現在姿態區塊，就是 @eq:reset 的 $bold(J)_r (dth)$，教科書常把它省略；@ch:gal 的 SO(3) 圖顯示被省略的項隨修正量以三次方成長。在右不變座標卡下，差異會耦合姿態、速度與位置，因此再也不能忽略；而且同一個矩陣會在 @ch:gnlm 的 GN/LM 每一次迭代中被套用。

修正 $delta$ 之後，共變異數重新以新估測值為中心表示。對兩種座標卡：
$ bold(J)_"reset"^"left" = mat(Gamma_1(-dth), 0; 0, bold(I)_12), wide
  bold(J)_"reset"^"right" = mat(sum_(k >= 0) op("ad")(bold(xi)_"nav")^k / (k+1)!, 0; 0, bold(I)_6), $ <eq:resetR>
其中 $op("ad")$ 見 @app:ops。兩者都是有限映射，而非一階近似。

== 新座標卡下的離散轉移

範例不另外推導第二個轉移矩陣，而是把物理座標卡的結果做共軛：
$ bold(F)_"native" = bold(J)_"phys"(hat(bold(x))^+)^(-1) space bold(F)_"phys" space bold(J)_"phys"(hat(bold(x))), wide
  bold(Q)_"native" = bold(J)_"phys"(hat(bold(x))^+)^(-1) space bold(Q)_"phys" space bold(J)_"phys"(hat(bold(x))^+)^(-top). $ <eq:conj>
因此在線性化精度內，Step3 傳遞的物理共變異數與 Step2 相同；結果上的差異來自誤差定義，而非積分。

== 右不變誤差及其動態 <sec:rinv>

把誤差定義為真值與估測擴展位姿之間的群差，真值在左：
$ bold(eta) = bold(X) hat(bold(X))^(-1) = mat(R Rh^top, v - R Rh^top hat(v), p - R Rh^top hat(p); 0, 1, 0; 0, 0, 1), wide bold(xi) = op("Log")(bold(eta)). $ <eq:rinv>
一階下 $bold(xi)_theta$ 是*世界座標系*的姿態誤差，且 $bold(xi)_v approx v - bold(E) hat(v)$、$bold(xi)_p approx p - bold(E) hat(p)$——即座標卡 @eq:rightchart。沿 IMU 流微分，並帶入偏差誤差 $delta bg = bg - hat(bg)$、$delta ba = ba - hat(ba)$，得到 $dot(bold(xi)) = bold(A) bold(xi) + bold(G) bold(n)$，兩者並列如下：

$ bold(A)_"left (Step1/2)" = mat(
  -hx(w), 0, 0, -I3, 0;
  -Rh hx(a), 0, 0, 0, -Rh;
  0, I3, 0, 0, 0;
  0, 0, 0, 0, 0;
  0, 0, 0, 0, 0), $
$ bold(A)_"right-invariant (Step3)" = mat(
  0, 0, 0, -Rh, 0;
  hx(g), 0, 0, -hx(hat(v)) Rh, -Rh;
  0, I3, 0, -hx(hat(p)) Rh, 0;
  0, 0, 0, 0, 0;
  0, 0, 0, 0, 0). $ <eq:Ainv>

請看兩個 9×9 導航區塊（左上）。在左座標卡下它們含有輸入 $w$、$a$ 與估測值 $Rh$。在右不變座標卡下它們只含 $hx(g)$ 與 $I3$。估測值被移到了偏差欄與雜訊矩陣中，
$ bold(G)_"Step3" = mat(-Rh, 0, 0, 0; -hx(hat(v)) Rh, -Rh, 0, 0; -hx(hat(p)) Rh, 0, 0, 0; 0, 0, I3, 0; 0, 0, 0, I3)
  = mat(-op("Ad")_(hat(bold(X))) mat(bold(I)_6; 0), 0; 0, bold(I)_6), $ <eq:Ginv>
其中 $op("Ad")$ 見 @app:ops。由此得到兩個結果，也正是下方圖表要測試的：姿態列不再依賴當前的姿態估測值，因此大的姿態誤差不會污染自身的傳遞；世界座標系的量測得到簡單的 Jacobian（用於 @ch:cstar）。

== Step4：隨狀態移動的偏差座標

Step3 保留加法式偏差，因此 @eq:Ainv 中它們的耦合欄仍帶有 $Rh$、$hat(v)$、$hat(p)$。Step4 改變*偏差*的座標卡：
$ mat(delta bg; delta ba) = op("Ad")_(Rh, hat(v))^(-1) space bold(J)_(-op("ad"))(bold(xi)_(theta v)) space mat(bold(xi)_(b g); bold(xi)_(b a)), wide
  op("Ad")_(Rh, hat(v)) = mat(Rh, 0; hx(hat(v)) Rh, Rh), wide
  bold(J)_(-op("ad"))(bold(xi)) = sum_(k >= 0) (-op("ad")(bold(xi)))^k / (k+1)!, $ <eq:step4bias>
使用 $op("Ad")$、$op("ad")$ 的 6×6 限制。其物理 Jacobian 在偏差區塊帶有 $op("Ad")_(Rh, hat(v))^(-1)$，其重置 Jacobian 是 $mat(op("ad")(bold(xi)_"nav"), 0; op("ad")(bold(xi)_b), op("ad")(bold(xi)_(theta v)))$ 的 15×15 級數。偏差的不確定性以與導航誤差相同的移動座標系表示。

== 範例中的 Step1–Step4

能區分各座標卡的情境是 `pure_dr`（只有 IMU 與載體速度；全域偏航角不可觀測），並以 `heading_dropout` 作為對照。
#two(fig("c3_pure_dr_pos.svg", [`pure_dr`，KF，種子 0。四個配方的位置誤差都在成長；在此種子上 Step3 與 Step4 低於 Step1/2。]),
     fig("c3_pure_dr_att.svg", [`pure_dr`，KF 姿態誤差，種子 0。不可觀測的偏航角漂移；在此種子上不變座標卡漂移較少。]))
#two(fig("c3_pure_dr_bars.svg", [`pure_dr`，KF，四個種子平均。Step1–4 的位置 RMSE 為 0.96 / 0.96 / 0.92 / 0.87 m；NEES15/15 為 1.28 / 1.28 / 1.20 / 1.13。全部過度自信；不變座標卡較輕微。]),
     fig("c3_dropout_att.svg", [`heading_dropout`，KF 姿態誤差。在陰影窗口內四者漂移相同，航向回來時一起回復：沒有任何座標卡能補上缺失的資訊。]))

#warn("解讀這些圖")[
  `pure_dr` 的差異是真實的，但很小，四個種子無法建立排名。這些圖支持的是：當姿態觀測不佳時，右不變誤差改善*一致性*，因為其傳遞 @eq:Ainv 不依賴姿態估測值。它不改善*可觀測性*。
]

#oneline[
  不變誤差 = 把估測值從 $bold(A)$ 的導航區塊移出，放進偏差欄與雜訊欄（@eq:Ainv–@eq:Ginv）。讀取與搬運共變異數需要 @eq:Jphys 與 @eq:resetR。Step4 進一步重新表示偏差（@eq:step4bias）。
]

// ---------------------------------------------------------------- 4
= 切群上的 EqF（Step5A、C15A） <ch:tg>

== 為什麼要擴展狀態

在 @eq:Ainv 中，偏差欄 $-Rh$、$-hx(hat(v)) Rh$、$-hx(hat(p)) Rh$ 正是 $-op("Ad")_(hat(bold(X)))$ 的前兩個欄區塊。若偏差是完整的 9 維向量 $bold(b) = (bg, ba, bnu)$，與導航代數的三列全部配對，耦合就會是完整的 $-op("Ad")$；再把偏差誤差以被 $op("Ad")$ 移動的座標系表示，耦合就成為常數 $-bold(I)_9$。這就是切群 $"TG" = "SE"_2(3) times.l frak(s e)_2(3)$，狀態為 $(bold(X), bold(b)) in RR^18$。

第三個區塊 $bnu$ 是*虛擬的*：代數的位置列沒有對應的感測器。它以類似速度的項進入流：
$ mat(R^+; v^+; p^+; bg^+; ba^+; bnu^+) = mat(
  R exp(h hx(w));
  v + h g + h R Gamma_1(h w) a;
  p + h v + 1/2 h^2 g + h^2 R Gamma_2(h w) a - h R Gamma_1(h w) bnu;
  bg;
  ba;
  bnu), $ <eq:tgflow>
亦即 TG 濾波器建模的是 $dot(p) = v - R bnu$。物理上 $bnu equiv 0$；本章其餘部分討論濾波器該如何知道這件事。

== TG 誤差動態：常數耦合

以伴隨搬運載體輸入，
$ bold(u) = op("Ad")_(hat(bold(X))) mat(w; a; -hat(bnu)) + mat(0; g; hat(v)). $ <eq:u>
TG 座標卡下 18×18 的連續誤差動態為
$ bold(A)_"TG" = mat(bold(A)_"nav", -bold(I)_9; 0, op("ad")(bold(u))), wide
  bold(A)_"nav" = mat(0, 0, 0; hx(g), 0, 0; 0, I3, 0), wide
  bold(G)_"TG" = mat(-op("Ad")_(hat(bold(X))) mat(bold(I)_6; 0), 0; 0, op("Ad")_(hat(bold(X))) mat(bold(I)_6; 0)). $ <eq:Atg>
與 @eq:Ainv 對照，導航到偏差的耦合現在是 $-bold(I)_9$：沒有 $Rh$、$hat(v)$、$hat(p)$。對狀態的依賴移進了偏差區塊 $op("ad")(bold(u))$ 與 $bold(G)$。範例以 RK4 積分 @eq:Atg 得到 $bold(F)$，並以 Simpson 法則積分雜訊欄。

== TG 的 retraction 與物理 Jacobian

TG retraction 的偏差部分是 @eq:step4bias 的 9×9 版本：
$ mat(delta bg; delta ba; delta bnu) = op("Ad")_(hat(bold(X)))^(-1) space bold(J)_(-op("ad"))(bold(xi)_"nav") space bold(xi)_b, wide
  bold(J)_"phys"^"TG" = mat(bold(J)_"phys"^"nav", 0; 0, op("Ad")_(hat(bold(X)))^(-1)) in RR^(18 times 18), $ <eq:tgphys>
其中 $bold(J)_"phys"^"nav"$ 是 @eq:Jphys 的 9×9 區塊。物理座標卡現在有 18 個元素，最後三個是載體座標系下的 $delta bnu$。

== 約束

取問題最容易顯現的最簡單情形：先驗導航為恆等、修正量為 $delta p = (delta p_x, 0, 0)$ 與 $delta bg = (0, delta b_y, 0)$，且原生 TG 修正量的建構使其*一階*虛擬擾動為零。有限 retraction @eq:tgphys 則給出
$ bnu^"new" = -1/2 hx(delta p) delta bg, $ <eq:bnu>
一個二階的非零虛擬偏差。曲面 $bnu = 0$ 在 TG retraction 下不是不變的：任何同時觸及位置與陀螺儀偏差的有限修正都會離開它。

#fig("constraints.svg", [`constraints.csv`。TG 有限 retraction 精確遵循 @eq:bnu（虛線為預測）；縮減版 C15 的 retraction 維持為零。這只是所推導的子空間，不是全域性的陳述。], w: 70%)

四種操作常被混為一談；它們是不同的矩陣：
#table(columns: (auto, 1fr, 1fr), inset: 5pt, stroke: 0.4pt + luma(170),
  [*操作*], [*它做什麼*], [*是貝氏更新嗎？*],
  [縮減表示（C15）], [狀態中沒有 $bnu$；retraction 永不離開曲面], [是——是另一個模型],
  [有限雜訊錨定], [量測 $bold(z) = 0$、$bold(H) = mat(0, 0, 0, 0, 0, I3)$、雜訊 $bold(V)_a$], [是——每次套用都加入證據],
  [一階切向變異數為零], [先驗 $bold(P)_(nu nu) = 0$；線性支撐受限], [只到一階；@eq:bnu 會重新引入 $bnu$],
  [硬性平均值鉗制], [更新後設 $hat(bnu) = 0$，$bold(P)$ 不動], [否——平均值與共變異數不一致])

== C15：縮減嵌入

C15A 是把 $bnu$ 及其列與欄從 TG 刪除後得到的 15 維濾波器。其導航座標卡為 @eq:rightchart、偏差為加法、流為 @eq:step2flow——這就是 Step3。`constrainedEmbedding` 測試以相容的 $bold(xi)_b = bold(J)_(-op("ad"))^(-1) op("Ad") (delta bg, delta ba, 0)$ 把 C15 的修正提升到 TG，並在 $bnu = 0$ 下驗證兩者在 $10^(-9)$ 內一致：C15 是 TG 限制在約束曲面上的結果，而非其近似。在 `metrics.csv` 中 Step3 與 C15A 在 $10^(-8)$ 內一致。

== 範例中的 Step3、Step4、Step5A、C15A

#fig("c4_pure_dr_bars.svg", [`pure_dr`，KF，四個種子平均。Step4 與 Step5A 數值上相近（0.865 對 0.866 m；NEES 1.13 對 1.12）：讓 $bnu$ 自由的 18 維 TG 在此相對 Step4 增益不多。Step3 = C15A。], w: 70%)

錨定研究刻意對 $bnu$ 使用寬先驗（$0.01 I3$）使其產生影響，藉此隔離虛擬偏差的處理方式：
#two(fig("anchor_rmse.svg", [位置 RMSE：無錨定的 TG、每 0.2 s 一次 $0.001 (m\/s)^2$ 錨定的 TG，以及 C15。`matched_heading`：相同。`pure_dr`：1.10 / 0.90 / 1.23 m。]),
     fig("anchor_nees.svg", [同一研究的 NEES15/15：0.61–0.82，全都保守，原因是被放大的先驗。]))
#fig("anchor_bnu.svg", [`pure_dr` 中每個種子的最終 $|bnu|$。無錨定時虛擬偏差漂移到 $3$–$10 times 10^(-3)$ m/s；錨定使其維持在 $10^(-3)$ 附近；C15 在結構上為零。], w: 60%)

#warn("錨定研究沒有隔離的東西")[
  C15 同時改變了動態（@eq:tgflow 中沒有 $bnu$ 項）、偏差 retraction 與高斯分布族。因此 `pure_dr` 的排序不能只歸因於約束曲面的曲率，而且封存的道路資料參數並未在此重現。
]

#oneline[
  切群以一個沒有感測器的潛在 $bnu$ 為代價，換得常數的導航到偏差耦合（@eq:Atg）。一般而言，有限的 TG 修正會離開 $bnu = 0$（@eq:bnu）。兩種一致的回應是：加入證據（錨定）或移除該座標（C15）。
]

// ---------------------------------------------------------------- 5
= 輸出近似：中點（C-star）輸出（Step5B、C15B） <ch:cstar>

== 不變座標卡下的載體速度量測

速度感測器給出 $bold(z) = R^top v + bold(n)$。以當前估測值把殘差旋轉到世界座標系，並以右不變擾動 @eq:rightchart 展開：
$ bold(r) = Rh bold(z) - hat(v) = Rh R^top v - hat(v) = bold(E)^top (bold(E) hat(v) + Gamma_1(bold(xi)_theta) bold(xi)_v) - hat(v) = Gamma_1(-bold(xi)_theta) bold(xi)_v. $ <eq:rexact>
一階下 $bold(r) = bold(xi)_v$：Jacobian 是常數。再往下一階，
$ Gamma_1(-bold(xi)_theta) bold(xi)_v = bold(xi)_v + 1/2 hx(bold(xi)_v) bold(xi)_theta + dots, $
把二階項中的 $bold(xi)_v$ 換成觀測到的 $bold(r)$，得到兩種輸出模型
$ mat(bold(H)_A; bold(H)_B) = mat(0, I3, 0, 0, 0; 1/2 hx(bold(r)), I3, 0, 0, 0), wide
  bold(V)_"world" = Rh bold(V)_"body" Rh^top. $ <eq:HAB>
$bold(H)_B$ 就是 C-star（中點）輸出。它是 Step5A 與 Step5B 之間、以及 C15A 與 C15B 之間的唯一差異，且只套用在單趟 KF 的增益列上。

== 餘項的階數

對無雜訊的受擾狀態，兩種殘差模型留下不同的餘項：
$ mat(bold(e)_A; bold(e)_B) = mat(bold(r) - bold(xi)_v; bold(r) - bold(xi)_v - 1/2 hx(bold(r)) bold(xi)_theta) = mat(O(|bold(xi)|^2); O(|bold(xi)|^3)). $ <eq:remainder>
#fig("remainder.svg", [`remainder.csv`，方向 1。尺度減半時，一般餘項除以 4，中點餘項除以 8；測試檢查七個方向與五個尺度，比值須落在 $4 plus.minus 0.3$ 與 $8 plus.minus 0.4$ 內。], w: 66%)

#warn("三次餘項是局部、無雜訊的陳述")[
  有雜訊時，$bold(H)_B$ 經由 $bold(r)$ 依賴量測值，因此增益變得與資料相關。上述內容並不蘊含整段運行的後驗校準或更低的 RMSE。
]

== 範例中的 A 對 B（KF）

#two(fig("c5_recovery_kf.svg", [從 1.2 rad 偏航誤差出發、速度先驗窄而偏航先驗寬（真值 0）的一次載體速度更新。輸出 A 落在 $+0.27$ rad，輸出 B 落在 $-0.17$ rad：單步結果不同，兩者皆未收斂。]),
     fig("c5_pure_dr_bars.svg", [`pure_dr`，KF，四個種子平均。B 把位置 RMSE 從 0.866 降到 0.813 m（Step5）、從 0.919 降到 0.861 m（C15），並把 NEES15/15 從 1.12/1.20 帶到 1.07/1.13——在四個種子所能分辨的範圍內。]))

#oneline[
  C-star 只改一列 Jacobian（@eq:HAB），其他什麼都不改。它的效果受限於單次線性化所能做到的事。
]

// ---------------------------------------------------------------- 6
= 迭代求解器：作為固定先驗 MAP 的 GN 與 LM <ch:gnlm>

上面的每個配方都是單趟濾波器。同一組先驗、概似與座標卡可以用迭代方式求解；本章把 KF 更新寫成該求解器的第一次迭代。

== KF 更新就是一步 Gauss–Newton

在先驗的原生切空間中參數化後驗，並以先驗平方根 $bold(L)$（$bold(P)^- = bold(L) bold(L)^top$）白化：
$ bold(x)(bold(z)) = op("retract")(hat(bold(x))^-, bold(L) bold(z)), wide
  C(bold(z)) = 1/2 bold(z)^top bold(z) + 1/2 bold(r)(bold(x)(bold(z)))^top bold(V)^(-1) bold(r)(bold(x)(bold(z))). $ <eq:cost>
先驗只進入一次，即 $1/2 bold(z)^top bold(z)$，並保持固定。在當前迭代點線性化殘差，
$ mat(bold(A); bold(B); bold(g)) = mat(
  bold(H)_"phys"(bold(x)) space bold(J)_"phys"(bold(x)) space bold(J)_"reset"(bold(L) bold(z)) space bold(L);
  I + bold(A)^top bold(V)^(-1) bold(A);
  bold(A)^top bold(V)^(-1) bold(r) - bold(z)), $ <eq:gn>
Gauss–Newton 與 Levenberg–Marquardt 的步長為
$ Delta bold(z)_"GN" = bold(B)^(-1) bold(g), wide
  Delta bold(z)_"LM" = (bold(B) + lambda op("diag")(bold(B)))^(-1) bold(g), $ <eq:steps>
其中 $lambda$ 在試探被拒絕後乘以 10、被接受後除以 3。在 $bold(z) = 0$ 處，一步 GN 等於 @eq:joseph 的卡爾曼修正（對 $bold(B)^(-1)$ 套用矩陣反演引理）：KF 就是第一次迭代。

== 後驗共變異數

最後一次被接受的迭代之後，共變異數由未阻尼的資訊矩陣形成，並經最終重置映射一次：
$ bold(P)^+ = bold(J)_"reset"(bold(L) bold(z)) space bold(L) space bold(B)^(-1) space bold(L)^top space bold(J)_"reset"(bold(L) bold(z))^top . $ <eq:gnpost>
LM 阻尼穩定搜尋，但從不縮小後驗。停止狀態——`gradient`、`step`、`cost`、`stalled`、`capped`、`time_budget`——逐次更新記錄；只有前三者代表收斂。

== 為什麼先驗必須保持固定

若把先驗換成前一次迭代的後驗，就會以更小的 $bold(L)$ 再加一次 $1/2 bold(z)^top bold(z)$：同一筆量測在每次迭代都被重複計算，共變異數會塌縮。`gaussian` 測試強制線性情形：KF、GN 與 LM 無論迭代次數為何，都必須回傳 $bold(P)^+ = (bold(P)^(-1) + bold(H)^top bold(V)^(-1) bold(H))^(-1)$。

== 範例中所有配方的 GN/LM

#fig("recovery.svg", [`recovery.csv`：@ch:cstar 的回復問題，涵蓋所有配方與後端。GN 與 LM 花 4–5 次迭代把 cost 從 1020 降到 0.36，每個配方都達到 $4 times 10^(-4)$ rad；座標卡與輸出變體不再有影響。], w: 78%)
#two(fig("bars_pure_dr_rmse.svg", [`pure_dr`，四個種子平均，所有配方與後端。GN/LM 使 RMSE 降低 3–6%，並讓 A 與 B 完全一致（各列在 $10^(-8)$ 內相同）。]),
     fig("bars_pure_dr_nees.svg", [`pure_dr` 的 NEES15/15。迭代讓每個配方朝 1 移動 0.05–0.15；沒有一個到達。在 `matched_heading` 中 GN/LM 沒有可量測的改變。]))

#oneline[
  GN/LM = 以相同先驗和更新後的線性化重複卡爾曼步驟（@eq:gn–@eq:steps），然後回報 @eq:gnpost。它們把所陳述的問題解得更好；但不改變問題的假設。
]

// ---------------------------------------------------------------- 7
= 解讀診斷指標：當模型是錯的 <ch:diag>

== Cost 不等於真相

從先驗偏航角 1.2 rad、真值 0、量測雜訊 0.05 rad 做一次航向更新：
#two(fig("assumptions.svg", [後驗偏航誤差。正確的概似：0.0015 rad。航向偏置 0.8 rad：濾波器落在 0.80，也就是資料所說的位置。過度自信的先驗（$10^(-5) "rad"^2$）：正確的量測被忽略，殘留 1.195 rad。]),
     fig("assumptions_cost.svg", [相同案例的 GN cost 前後值。航向錯誤的案例最終 cost *最低*（0.04）：最佳化器完美地解了它的問題。過度自信的案例幾乎不動（288 → 287）。]))
每個配方與後端都出現完全相同的數字：沒有任何座標卡或求解器能掩蓋錯誤的假設。

== 未建模的偏差跳變

#two(fig("trace_bias_mismatch_nees.svg", [在 6 s 時陀螺儀 z 軸 +0.12 rad/s 跳變、濾波器中偏差隨機漫步為零之後的 NEES15/15。所有配方到 12 s 時都升到約 300：共變異數凍結而誤差持續成長。]),
     fig("trace_bias_mismatch_bg.svg", [陀螺儀偏差誤差範數：濾波器緩慢跟上跳變（6 s 後仍殘留 0.05 rad/s），因為其程序模型說偏差不會動。]))
`metrics.csv` 對每個配方與後端都回報 NEES15/15 ≈ 72。不變座標卡、切群與迭代求解器全都給出相同答案，因為它們都沒有觸及程序雜訊模型。

== 完整 3 維速度對前向速度 + NHC

Step2，真值側向載體速度為 0 或 0.6 m/s，航向始終可用，各速度通道變異數 $0.0025 (m\/s)^2$。NHC 變體使用同一個帶雜訊的前向樣本，並把側向與垂直通道設為零。
#two(fig("slip_rmse.svg", [對數尺度。無側滑時 NHC 是有效的約束且略有幫助（0.086 對 0.099 m）。側滑 0.6 m/s 時 NHC 的概似是錯的：2.98 m。]),
     fig("slip_cov.svg", [側向速度的 95% 覆蓋率。量測 3 維：0.97。NHC 無側滑：0.99。NHC 有側滑：0.00——在側向上自信地錯了。]))
#fig("slip_nis.svg", [平均速度 NIS（3 個自由度）。NHC 即使錯誤也會*降低* NIS（1.2–1.7 對 2.75），因為其三個通道中有兩個在建構上無雜訊；單靠 NIS 不會標示出這個失效。對真值的覆蓋率則會。], w: 60%)

#oneline[
  對真值的 NEES 與覆蓋率能揭露模型失配；cost 與 NIS 不能。解方——偏差隨機漫步、量測模型中的側滑——在模型裡，不在幾何裡。
]

// ---------------------------------------------------------------- 附錄
#pagebreak()
#counter(heading).update(0)
#set heading(supplement: [], numbering: (..nums) => {
  let n = nums.pos()
  if n.len() == 1 { "附錄 " + numbering("A", n.at(0)) + "：" } else { numbering("A.1", ..n) }
})

= 共同基礎：狀態、運算子與量尺 <app:common>

== 狀態、座標系與 IMU 模型 <app:state>

世界座標系 $W$ 與載體（IMU）座標系 $B$；$R$ 把載體座標映到世界座標。重力是固定參數。
$ bold(x) = (R, v, p, bg, ba), wide R in "SO"(3), quad v, p in RR^3 "(world)", quad bg, ba in RR^3 "(body)", $
$ g = mat(0; 0; -9.81) #zh[（固定參數）]. $
IMU 樣本是載體座標系下的陀螺儀 $tilde(w)$ 與比力 $tilde(a)$，帶有白雜訊 $bold(n)$ 與隨機漫步偏差：
$ mat(tilde(w); tilde(a)) = mat(w; a) + mat(bg; ba) + mat(bold(n)_g; bold(n)_a), wide
  mat(dot(bg); dot(ba)) = mat(bold(n)_(b g); bold(n)_(b a)). $ <eq:imu>
時間為 $t$；一個傳遞區間的長度為 $h$。帶帽符號表示估測值；同一符號不帶帽為真值；上標 $+$ 表示傳遞或更新之後的值。

== 運算子 <app:ops>

*反對稱矩陣。* 對 $bold(x) in RR^3$，
$ hx(bold(x)) = mat(0, -x_3, x_2; x_3, 0, -x_1; -x_2, x_1, 0), wide hx(bold(x)) bold(y) = bold(x) times bold(y). $ <eq:skew>

*旋轉指數與 $Gamma$ 矩陣。* 令 $bold(phi) in RR^3$、$bold(Phi) = hx(bold(phi))$，
$ exp(bold(Phi)) = sum_(k >= 0) bold(Phi)^k / k!, wide
  Gamma_1(bold(phi)) = sum_(k >= 0) bold(Phi)^k / (k+1)!, wide
  Gamma_2(bold(phi)) = sum_(k >= 0) bold(Phi)^k / (k+2)!. $ <eq:gamma>
$exp(bold(Phi))$ 是旋轉矩陣；$Gamma_1$ 是 SO(3) 的左 Jacobian，因此 $Gamma_1(-bold(phi))$ 是右 Jacobian $bold(J)_r (bold(phi))$；$Gamma_2$ 是其二次積分。範例以級數（`gammas`）計算三者，測試將其與封閉形式比對。

*擴展位姿的伴隨與小伴隨。* 對導航三元組 $(R, v, p)$ 與切向量 $bold(xi) = (bold(xi)_theta, bold(xi)_v, bold(xi)_p)$，
$ op("Ad")_(R, v, p) = mat(R, 0, 0; hx(v) R, R, 0; hx(p) R, 0, R), wide
  op("ad")(bold(xi)) = mat(hx(bold(xi)_theta), 0, 0; hx(bold(xi)_v), hx(bold(xi)_theta), 0; hx(bold(xi)_p), 0, hx(bold(xi)_theta)). $ <eq:adjoint>
限制到 $(R, v)$ 的 6×6 版本去掉最後一個區塊列與區塊欄。

== 物理座標卡與分數 <app:yardstick>

每個配方以自己的座標儲存共變異數。為了比較，每個共變異數都映射一次到意義固定的物理誤差向量：
$ bold(e) = mat(op("Log")(Rh^top R); v - hat(v); p - hat(p); bg - hat(bg); ba - hat(ba)) in RR^15, wide
  #zh[順序為] (dth_"body", delta v_"world", delta p_"world", delta bg, delta ba), $ <eq:physical>
所有分數都在此計算：
$ mat(op("NEES")_15; "coverage"_z; op("NIS")) = mat(
  bold(e)^top bold(P)_"phys"^(-1) bold(e);
  Pr(|e_z| <= 1.96 sqrt(P_(z z)));
  bold(r)^top (bold(H) bold(P) bold(H)^top + bold(V))^(-1) bold(r)). $ <eq:scores>
`normalized_nees15` 把 $op("NEES")_15$ 的時間平均除以 15；一致的濾波器落在 1 附近。NIS 在速度更新後讀取（3 個自由度，期望 ≈ 3）。位姿 RMSE 是未經對齊的世界座標系直接誤差。

== 共同實驗 <app:experiment>

所有情境使用同一條封閉形式、變速的圓形軌跡；真值從不呼叫估測器。
$ mat(R(t); v(t)) = mat(R_z (0.3 t); R(t) mat(2 + 0.3 sin 0.7 t; 0; 0)), $
IMU 為 40 Hz（取區間中點樣本並保持），載體速度與航向每 0.2 s 一次。雜訊以帶種子的 `mt19937` 加上顯式 Box–Muller 轉換產生；所有配方接收相同的樣本與相同的先驗。

#table(columns: (auto, 1fr, 1fr), inset: 5pt, stroke: 0.4pt + luma(170),
  [*情境*], [*假設*], [*要看什麼*],
  [`matched_heading`], [固定偏差；IMU／速度／航向雜訊相符], [基準誤差、NEES、覆蓋率],
  [`heading_dropout`], [航向在運行的 35% 到 75% 之間缺失], [姿態／偏差不確定性的成長與回復],
  [`pure_dr`], [只有 IMU 與完整 3 維載體速度], [全域偏航角不可觀測],
  [`bias_mismatch`], [運行中段陀螺儀 z 軸 +0.12 rad/s 跳變，濾波器中偏差隨機漫步為零], [收斂的濾波器可以自信地錯])

先驗誤差在物理座標卡中抽樣，各軸標準差為
$ mat(sigma_theta; sigma_v; sigma_p; sigma_(b g); sigma_(b a)) = mat(0.05 "rad"; 0.1 "m/s"; 0.1 "m"; 0.02 "rad/s"; 0.05 "m/s"^2). $
四個種子只是示意，不是統計；同一種子內的時間樣本彼此相關。

= 符號對應程式碼
#set text(size: 9pt)
#table(columns: (1.15fr, 1.15fr, 0.8fr), inset: 4.5pt, stroke: 0.4pt + luma(170),
  [*符號／方程式*], [*函式*], [*檔案*],
  [$hx(dot)$, $exp$, $op("Log")$, $Gamma_1$, $Gamma_2$（@eq:skew, @eq:gamma）], [`hat`, `expSO3`, `logSO3`, `gammas`], [`src/kf3d/geometry.cpp`],
  [$op("Ad")$, $op("ad")$, $sum op("ad")^k \/ (k+1)!$（@eq:adjoint）], [`adjoint`, `ad`, `algebraJacobian`], [`src/kf3d/geometry.cpp`],
  [座標卡 @eq:leftchart, @eq:rightretract, @eq:step4bias, @eq:tgphys], [`retract`, `local`], [`src/kf3d/geometry.cpp`],
  [$bold(J)_"phys"$ @eq:Jphys, $bold(J)_"reset"$ @eq:resetR], [`physicalJacobian`, `resetJacobian`], [`src/kf3d/geometry.cpp`],
  [流 @eq:step1flow, @eq:step2flow；$bold(F)$ @eq:F1, @eq:F2], [`physicalFlow`], [`src/kf3d/propagation.cpp`],
  [$bold(G)$ @eq:G1, $bold(Q)$ @eq:Q, 共軛 @eq:conj], [`noiseRoot`, `predict`], [`src/kf3d/propagation.cpp`],
  [TG 流 @eq:tgflow, $bold(A)_"TG"$ @eq:Atg, RK4], [`tgFlow`, `dynamics`, `transition`], [`src/kf3d/propagation.cpp`],
  [Joseph @eq:joseph, 重置 @eq:reset, QR 平方根 @eq:sqrt], [`update`, `compress`], [`src/kf3d/filter.cpp`],
  [$bold(H)_A$, $bold(H)_B$ @eq:HAB], [`observeVelocity`], [`src/kf3d/filter.cpp`],
  [cost @eq:cost, GN/LM @eq:gn–@eq:steps, 後驗 @eq:gnpost], [`update`（非 KF 分支）, `GnSolver`, `LmSolver`], [`src/kf3d/filter.cpp`],
  [錨定 $bold(H) = mat(0, dots, I3)$], [`observeVirtualBias`], [`src/kf3d/filter.cpp`],
  [情境與研究產生器], [`events`, `*Csv`], [`examples/teaching.cpp`],
  [解析／有限差分 oracle], [`geometry`, `zoh`, `gaussian`, `prediction`, `equivalence`, `remainder`], [`tests/math_contracts.cpp`])
#set text(size: 10.5pt)

= 重新產生圖表
```bash
./build/kf_math_tests                       # 解析 + 有限差分契約
./build/kf_teaching results/teaching 4 12   # 本手冊使用的所有 CSV
python3 docs/handnote/make_figs.py            # fig/*.svg、metrics_mean.csv
typst compile docs/handnote/handnote.typ      # 本 PDF（Typst 0.15 + Noto Sans CJK TC）
```
本手冊的圖表由標準函式庫的 SVG 腳本（`make_figs.py`，不使用第三方套件）從 CSV 繪出；估測器程式碼未經任何修改。相同的二進位檔、平台與參數可逐位元組重現這些 CSV；圖說中引用的四種子平均值由這些檔案四捨五入而來。

= 平均指標，4 個種子，12 s
#let rows = csv("metrics_mean.csv")
#table(columns: 7, inset: 3.5pt, stroke: 0.3pt + luma(190), align: (left, left, left, right, right, right, right),
  ..rows.flatten().map(c => text(size: 8pt, c)))
