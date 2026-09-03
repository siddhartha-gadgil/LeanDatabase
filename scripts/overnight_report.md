# Overnight `sql_equiv_llm` run

Wall time: 3.86 h · Total files: 1885


## Literature (64 files) — 22.6¢

- PROVED: 36
- DISPROVED: 10
- INCONCLUSIVE: 12
- ELAB_ERROR: 5
- ↳ disproofs: 10 Lean set-decide, **0 sqlglot-certified multiset**, 1 spurious(rejected)

## Calcite (397 files) — 386.5¢

- PROVED: 99
- DISPROVED: 10
- INCONCLUSIVE: 141
- TIMEOUT: 2
- ELAB_ERROR: 117
- ↳ disproofs: 10 Lean set-decide, **0 sqlglot-certified multiset**, 28 spurious(rejected)

## CrossSkill (1424 files) — 387.8¢

- PROVED: 82
- DISPROVED: 120
- INCONCLUSIVE: 596
- TIMEOUT: 41
- ELAB_ERROR: 585
- ↳ disproofs: 71 Lean set-decide, **0 sqlglot-certified multiset**, 0 spurious(rejected)

**Disproof provenance (all datasets): 91 Lean-verified (set) · 0 sqlglot-certified (multiset) · 29 spurious rejected**


**Total estimated cost: 796.9¢ ($7.97)**


## Per-file

| dataset | file | outcome | method | cost¢ | time s | verified | artifact |
|---|---|---|---|---|---|---|---|
| Calcite | 1 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/1.lean |
| Calcite | 10 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.2596 | 47.7 |  |  |
| Calcite | 100 | INCONCLUSIVE | exhausted | 1.7164 | 146.6 |  |  |
| Calcite | 101 | ELAB_ERROR |  | 0.0 | 138.9 |  |  |
| Calcite | 102 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/102.lean |
| Calcite | 103 | INCONCLUSIVE |  | 0.0 | 134.8 |  |  |
| Calcite | 104 | INCONCLUSIVE | exhausted | 4.9149 | 336.1 |  |  |
| Calcite | 105 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/105.lean |
| Calcite | 106 | INCONCLUSIVE | exhausted | 0.6635 | 19.6 |  |  |
| Calcite | 107 | ELAB_ERROR |  | 0.0 | 526.1 |  |  |
| Calcite | 108 | PROVED | sql_equiv | 0.0 | 4.8 | yes | Bench/Calcite/Proven/108.lean |
| Calcite | 109 | INCONCLUSIVE | exhausted | 5.3406 | 399.8 |  |  |
| Calcite | 11 | ELAB_ERROR |  | 0.0 | 91.5 |  |  |
| Calcite | 110 | PROVED | sql_equiv | 0.0 | 4.8 | yes | Bench/Calcite/Proven/110.lean |
| Calcite | 111 | ELAB_ERROR |  | 0.0 | 162.6 |  |  |
| Calcite | 112 | ELAB_ERROR |  | 0.0 | 144.8 |  |  |
| Calcite | 113 | ELAB_ERROR |  | 0.0 | 184.1 |  |  |
| Calcite | 114 | ELAB_ERROR |  | 0.0 | 178.1 |  |  |
| Calcite | 115 | ELAB_ERROR |  | 0.0 | 142.9 |  |  |
| Calcite | 116 | INCONCLUSIVE | exhausted | 2.7697 | 184.2 |  |  |
| Calcite | 117 | ELAB_ERROR |  | 0.0 | 176.7 |  |  |
| Calcite | 118 | ELAB_ERROR |  | 0.0 | 172.1 |  |  |
| Calcite | 119 | ELAB_ERROR |  | 0.0 | 156.8 |  |  |
| Calcite | 12 | INCONCLUSIVE | exhausted | 3.228 | 245.4 |  |  |
| Calcite | 120 | INCONCLUSIVE | exhausted | 4.1691 | 302.7 |  |  |
| Calcite | 121 | INCONCLUSIVE |  | 0.0 | 243.1 |  |  |
| Calcite | 122 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/122.lean |
| Calcite | 123 | INCONCLUSIVE | exhausted | 1.147 | 80.8 |  |  |
| Calcite | 124 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.2607 | 45.1 |  |  |
| Calcite | 125 | PROVED | llm | 0.2479 | 31.9 | yes | Bench/Calcite/Proven/125.lean |
| Calcite | 126 | INCONCLUSIVE | exhausted | 0.6523 | 16.1 |  |  |
| Calcite | 127 | ELAB_ERROR |  | 0.0 | 124.8 |  |  |
| Calcite | 128 | INCONCLUSIVE | exhausted | 0.7327 | 26.9 |  |  |
| Calcite | 129 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.2674 | 30.4 |  |  |
| Calcite | 13 | INCONCLUSIVE | exhausted | 4.4673 | 342.3 |  |  |
| Calcite | 130 | PROVED | llm | 0.9859 | 63.2 | yes | Bench/Calcite/Proven/130.lean |
| Calcite | 131 | PROVED | sql_equiv | 0.0 | 5.3 | yes | Bench/Calcite/Proven/131.lean |
| Calcite | 132 | ELAB_ERROR |  | 0.0 | 4.4 |  |  |
| Calcite | 133 | INCONCLUSIVE | exhausted | 0.6591 | 16.5 |  |  |
| Calcite | 134 | INCONCLUSIVE | exhausted | 4.4782 | 343.6 |  |  |
| Calcite | 135 | PROVED | sql_equiv | 0.0 | 5.9 | yes | Bench/Calcite/Proven/135.lean |
| Calcite | 136 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/136.lean |
| Calcite | 137 | INCONCLUSIVE | exhausted | 1.0954 | 98.7 |  |  |
| Calcite | 138 | INCONCLUSIVE | exhausted | 1.3765 | 93.0 |  |  |
| Calcite | 139 | ELAB_ERROR |  | 0.0 | 95.2 |  |  |
| Calcite | 14 | INCONCLUSIVE | exhausted | 7.1148 | 529.0 |  |  |
| Calcite | 140 | PROVED | sql_equiv | 0.0 | 4.8 | yes | Bench/Calcite/Proven/140.lean |
| Calcite | 141 | INCONCLUSIVE | exhausted | 5.5018 | 414.6 |  |  |
| Calcite | 142 | PROVED | sql_equiv | 0.0 | 4.5 | yes | Bench/Calcite/Proven/142.lean |
| Calcite | 143 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.268 | 117.0 |  |  |
| Calcite | 144 | PROVED | sql_equiv | 0.0 | 4.5 | yes | Bench/Calcite/Proven/144.lean |
| Calcite | 145 | INCONCLUSIVE | llm+safe | 3.0541 | 200.9 | NO |  |
| Calcite | 146 | INCONCLUSIVE |  | 0.0 | 91.4 |  |  |
| Calcite | 147 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.2568 | 104.0 |  |  |
| Calcite | 148 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.3122 | 131.3 |  |  |
| Calcite | 149 | ELAB_ERROR |  | 0.0 | 294.6 |  |  |
| Calcite | 15 | INCONCLUSIVE | exhausted | 1.9023 | 121.1 |  |  |
| Calcite | 150 | INCONCLUSIVE |  | 0.0 | 142.4 |  |  |
| Calcite | 151 | INCONCLUSIVE | exhausted | 4.8294 | 389.2 |  |  |
| Calcite | 152 | INCONCLUSIVE | exhausted | 0.6611 | 19.0 |  |  |
| Calcite | 153 | ELAB_ERROR |  | 0.0 | 100.4 |  |  |
| Calcite | 154 | ELAB_ERROR |  | 0.0 | 137.4 |  |  |
| Calcite | 155 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/155.lean |
| Calcite | 156 | INCONCLUSIVE | exhausted | 5.3823 | 399.9 |  |  |
| Calcite | 157 | ELAB_ERROR |  | 0.0 | 31.9 |  |  |
| Calcite | 158 | INCONCLUSIVE | exhausted | 0.6755 | 19.5 |  |  |
| Calcite | 159 | INCONCLUSIVE | exhausted | 3.9261 | 320.8 |  |  |
| Calcite | 16 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.306 | 31.2 |  |  |
| Calcite | 160 | INCONCLUSIVE | exhausted | 5.5514 | 383.2 |  |  |
| Calcite | 161 | INCONCLUSIVE | exhausted | 0.7327 | 25.8 |  |  |
| Calcite | 162 | ELAB_ERROR |  | 0.0 | 105.6 |  |  |
| Calcite | 163 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 3.3897 | 434.5 |  |  |
| Calcite | 164 | INCONCLUSIVE | exhausted | 2.939 | 222.8 |  |  |
| Calcite | 165 | INCONCLUSIVE | exhausted | 3.7796 | 290.6 |  |  |
| Calcite | 166 | DISPROVED(unverified-artifact) | plausible_sql | 0.3078 | 99.3 | NO |  |
| Calcite | 167 | PROVED | llm | 0.3024 | 15.6 | yes | Bench/Calcite/Proven/167.lean |
| Calcite | 168 | PROVED | sql_equiv | 0.0 | 5.5 | yes | Bench/Calcite/Proven/168.lean |
| Calcite | 169 | PROVED | sql_equiv | 0.0 | 5.3 | yes | Bench/Calcite/Proven/169.lean |
| Calcite | 17 | ELAB_ERROR |  | 0.0 | 146.4 |  |  |
| Calcite | 170 | PROVED | sql_equiv | 0.0 | 5.6 | yes | Bench/Calcite/Proven/170.lean |
| Calcite | 171 | PROVED | sql_equiv | 0.0 | 5.7 | yes | Bench/Calcite/Proven/171.lean |
| Calcite | 172 | PROVED | sql_equiv | 0.0 | 5.1 | yes | Bench/Calcite/Proven/172.lean |
| Calcite | 173 | ELAB_ERROR |  | 0.0 | 115.0 |  |  |
| Calcite | 174 | INCONCLUSIVE |  | 0.0 | 140.9 |  |  |
| Calcite | 175 | INCONCLUSIVE |  | 0.0 | 96.3 |  |  |
| Calcite | 176 | INCONCLUSIVE | exhausted | 4.792 | 333.7 |  |  |
| Calcite | 177 | PROVED | llm | 1.0019 | 63.3 | yes | Bench/Calcite/Proven/177.lean |
| Calcite | 178 | INCONCLUSIVE | exhausted | 2.1999 | 157.5 |  |  |
| Calcite | 179 | PROVED | llm | 0.2622 | 14.9 | yes | Bench/Calcite/Proven/179.lean |
| Calcite | 18 | PROVED | sql_equiv | 0.0 | 5.4 | yes | Bench/Calcite/Proven/18.lean |
| Calcite | 180 | INCONCLUSIVE | exhausted | 0.9746 | 54.8 |  |  |
| Calcite | 181 | PROVED | llm | 0.3256 | 21.8 | yes | Bench/Calcite/Proven/181.lean |
| Calcite | 182 | DISPROVED(unverified-artifact) | plausible_sql | 0.3892 | 100.0 | NO |  |
| Calcite | 183 | INCONCLUSIVE |  | 0.0 | 54.2 |  |  |
| Calcite | 184 | INCONCLUSIVE | exhausted | 6.5327 | 511.1 |  |  |
| Calcite | 185 | INCONCLUSIVE |  | 0.0 | 63.7 |  |  |
| Calcite | 186 | INCONCLUSIVE |  | 0.0 | 62.5 |  |  |
| Calcite | 187 | INCONCLUSIVE |  | 0.0 | 101.9 |  |  |
| Calcite | 188 | PROVED | llm | 0.4087 | 27.0 | yes | Bench/Calcite/Proven/188.lean |
| Calcite | 189 | DISPROVED(unverified-artifact) | plausible_sql | 1.5066 | 151.5 | NO |  |
| Calcite | 19 | PROVED | sql_equiv | 0.0 | 4.9 | yes | Bench/Calcite/Proven/19.lean |
| Calcite | 190 | ELAB_ERROR |  | 0.0 | 138.2 |  |  |
| Calcite | 191 | ELAB_ERROR |  | 0.0 | 169.4 |  |  |
| Calcite | 192 | ELAB_ERROR |  | 0.0 | 126.4 |  |  |
| Calcite | 193 | ELAB_ERROR |  | 0.0 | 163.1 |  |  |
| Calcite | 194 | ELAB_ERROR |  | 0.0 | 165.8 |  |  |
| Calcite | 195 | INCONCLUSIVE | exhausted | 1.2253 | 75.8 |  |  |
| Calcite | 196 | INCONCLUSIVE | exhausted | 0.7011 | 22.5 |  |  |
| Calcite | 197 | INCONCLUSIVE | exhausted | 5.6296 | 427.5 |  |  |
| Calcite | 198 | INCONCLUSIVE | exhausted | 5.0312 | 392.3 |  |  |
| Calcite | 199 | INCONCLUSIVE | exhausted | 6.5029 | 513.9 |  |  |
| Calcite | 2 | INCONCLUSIVE | exhausted | 5.2765 | 437.5 |  |  |
| Calcite | 20 | PROVED | sql_equiv | 0.0 | 4.3 | yes | Bench/Calcite/Proven/20.lean |
| Calcite | 200 | ELAB_ERROR |  | 0.0 | 140.6 |  |  |
| Calcite | 201 | ELAB_ERROR |  | 0.0 | 33.6 |  |  |
| Calcite | 202 | DISPROVED(unverified-artifact) | plausible_sql | 0.2742 | 30.0 | NO |  |
| Calcite | 203 | ELAB_ERROR |  | 0.0 | 125.2 |  |  |
| Calcite | 204 | INCONCLUSIVE | exhausted | 5.6108 | 426.9 |  |  |
| Calcite | 205 | ELAB_ERROR |  | 0.0 | 98.2 |  |  |
| Calcite | 206 | ELAB_ERROR |  | 0.0 | 56.5 |  |  |
| Calcite | 207 | INCONCLUSIVE | exhausted | 6.8243 | 552.7 |  |  |
| Calcite | 208 | PROVED | sql_equiv | 0.0 | 5.0 | yes | Bench/Calcite/Proven/208.lean |
| Calcite | 209 | ELAB_ERROR |  | 0.0 | 72.1 |  |  |
| Calcite | 21 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/21.lean |
| Calcite | 210 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.5028 | 90.3 |  |  |
| Calcite | 211 | INCONCLUSIVE | exhausted | 7.7017 | 584.3 |  |  |
| Calcite | 212 | INCONCLUSIVE |  | 0.0 | 112.7 |  |  |
| Calcite | 213 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/213.lean |
| Calcite | 214 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/214.lean |
| Calcite | 215 | INCONCLUSIVE | exhausted | 4.4605 | 307.5 |  |  |
| Calcite | 216 | PROVED | sql_equiv | 0.0 | 4.3 | yes | Bench/Calcite/Proven/216.lean |
| Calcite | 217 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/217.lean |
| Calcite | 218 | ELAB_ERROR |  | 0.0 | 95.7 |  |  |
| Calcite | 219 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 2.3296 | 181.5 |  |  |
| Calcite | 22 | INCONCLUSIVE | exhausted | 6.0248 | 462.0 |  |  |
| Calcite | 220 | PROVED | sql_equiv | 0.0 | 4.9 | yes | Bench/Calcite/Proven/220.lean |
| Calcite | 221 | ELAB_ERROR |  | 0.0 | 95.4 |  |  |
| Calcite | 222 | INCONCLUSIVE | exhausted | 4.8102 | 372.4 |  |  |
| Calcite | 223 | PROVED | sql_equiv | 0.0 | 5.4 | yes | Bench/Calcite/Proven/223.lean |
| Calcite | 224 | INCONCLUSIVE | exhausted | 2.6174 | 206.2 |  |  |
| Calcite | 225 | INCONCLUSIVE | exhausted | 4.068 | 278.1 |  |  |
| Calcite | 226 | PROVED | sql_equiv | 0.0 | 5.7 | yes | Bench/Calcite/Proven/226.lean |
| Calcite | 227 | ELAB_ERROR |  | 0.0 | 100.4 |  |  |
| Calcite | 228 | ELAB_ERROR |  | 0.0 | 135.3 |  |  |
| Calcite | 229 | ELAB_ERROR |  | 0.0 | 94.7 |  |  |
| Calcite | 23 | ELAB_ERROR |  | 0.0 | 162.2 |  |  |
| Calcite | 230 | ELAB_ERROR |  | 0.0 | 74.0 |  |  |
| Calcite | 231 | PROVED | sql_equiv | 0.0 | 4.4 | yes | Bench/Calcite/Proven/231.lean |
| Calcite | 232 | ELAB_ERROR |  | 0.0 | 69.3 |  |  |
| Calcite | 233 | PROVED | sql_equiv | 0.0 | 5.5 | yes | Bench/Calcite/Proven/233.lean |
| Calcite | 234 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 1.4845 | 117.5 |  |  |
| Calcite | 235 | ELAB_ERROR |  | 0.0 | 120.3 |  |  |
| Calcite | 236 | INCONCLUSIVE | exhausted | 4.337 | 313.4 |  |  |
| Calcite | 237 | INCONCLUSIVE |  | 0.0 | 225.8 |  |  |
| Calcite | 238 | PROVED | sql_equiv | 0.0 | 4.4 | yes | Bench/Calcite/Proven/238.lean |
| Calcite | 239 | INCONCLUSIVE | exhausted | 2.6831 | 216.7 |  |  |
| Calcite | 24 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.2781 | 27.5 |  |  |
| Calcite | 240 | INCONCLUSIVE | exhausted | 1.5036 | 130.6 |  |  |
| Calcite | 241 | ELAB_ERROR |  | 0.0 | 144.7 |  |  |
| Calcite | 242 | ELAB_ERROR |  | 0.0 | 100.2 |  |  |
| Calcite | 243 | INCONCLUSIVE | exhausted | 1.2334 | 87.8 |  |  |
| Calcite | 244 | INCONCLUSIVE | exhausted | 6.7342 | 514.7 |  |  |
| Calcite | 245 | ELAB_ERROR |  | 0.0 | 105.8 |  |  |
| Calcite | 246 | ELAB_ERROR |  | 0.0 | 102.0 |  |  |
| Calcite | 247 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.4659 | 61.6 |  |  |
| Calcite | 248 | INCONCLUSIVE | exhausted | 0.6565 | 17.1 |  |  |
| Calcite | 249 | DISPROVED(unverified-artifact) | plausible_sql | 0.5024 | 67.6 | NO |  |
| Calcite | 25 | INCONCLUSIVE | exhausted | 0.7139 | 23.9 |  |  |
| Calcite | 250 | INCONCLUSIVE | exhausted | 3.6841 | 269.7 |  |  |
| Calcite | 251 | ELAB_ERROR |  | 0.0 | 209.9 |  |  |
| Calcite | 252 | INCONCLUSIVE | exhausted | 1.4088 | 97.2 |  |  |
| Calcite | 253 | INCONCLUSIVE | exhausted | 4.3411 | 333.4 |  |  |
| Calcite | 254 | ELAB_ERROR |  | 0.0 | 143.0 |  |  |
| Calcite | 255 | ELAB_ERROR |  | 0.0 | 96.1 |  |  |
| Calcite | 256 | PROVED | sql_equiv | 0.0 | 4.5 | yes | Bench/Calcite/Proven/256.lean |
| Calcite | 257 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.2007 | 75.1 |  |  |
| Calcite | 258 | INCONCLUSIVE |  | 0.0 | 52.6 |  |  |
| Calcite | 259 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/259.lean |
| Calcite | 26 | PROVED | sql_equiv | 0.0 | 4.5 | yes | Bench/Calcite/Proven/26.lean |
| Calcite | 260 | ELAB_ERROR |  | 0.0 | 54.0 |  |  |
| Calcite | 261 | ELAB_ERROR |  | 0.0 | 67.8 |  |  |
| Calcite | 262 | INCONCLUSIVE | exhausted | 5.6879 | 400.8 |  |  |
| Calcite | 263 | ELAB_ERROR |  | 0.0 | 104.4 |  |  |
| Calcite | 264 | ELAB_ERROR |  | 0.0 | 338.2 |  |  |
| Calcite | 265 | PROVED | llm | 1.3948 | 92.7 | yes | Bench/Calcite/Proven/265.lean |
| Calcite | 266 | PROVED | sql_equiv | 0.0 | 6.3 | yes | Bench/Calcite/Proven/266.lean |
| Calcite | 267 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.6399 | 43.4 |  |  |
| Calcite | 268 | ELAB_ERROR |  | 0.0 | 184.6 |  |  |
| Calcite | 269 | INCONCLUSIVE | exhausted | 4.2492 | 318.0 |  |  |
| Calcite | 27 | INCONCLUSIVE | exhausted | 0.6781 | 21.8 |  |  |
| Calcite | 270 | PROVED | llm | 0.9914 | 57.6 | yes | Bench/Calcite/Proven/270.lean |
| Calcite | 271 | INCONCLUSIVE |  | 0.0 | 79.7 |  |  |
| Calcite | 272 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/272.lean |
| Calcite | 273 | ELAB_ERROR |  | 0.0 | 83.3 |  |  |
| Calcite | 274 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/274.lean |
| Calcite | 275 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/275.lean |
| Calcite | 276 | DISPROVED(unverified-artifact) | plausible_sql | 0.2894 | 40.2 | NO |  |
| Calcite | 277 | INCONCLUSIVE | exhausted | 0.6723 | 23.3 |  |  |
| Calcite | 278 | INCONCLUSIVE | exhausted | 4.6272 | 333.0 |  |  |
| Calcite | 279 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.3013 | 31.8 |  |  |
| Calcite | 28 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/28.lean |
| Calcite | 280 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/280.lean |
| Calcite | 281 | ELAB_ERROR |  | 0.0 | 7.1 |  |  |
| Calcite | 282 | ELAB_ERROR |  | 0.0 | 102.1 |  |  |
| Calcite | 283 | PROVED | sql_equiv | 0.0 | 4.5 | yes | Bench/Calcite/Proven/283.lean |
| Calcite | 284 | ELAB_ERROR |  | 0.0 | 97.0 |  |  |
| Calcite | 285 | INCONCLUSIVE | exhausted | 1.7638 | 148.0 |  |  |
| Calcite | 286 | INCONCLUSIVE | exhausted | 1.8554 | 122.6 |  |  |
| Calcite | 287 | ELAB_ERROR |  | 0.0 | 71.5 |  |  |
| Calcite | 288 | DISPROVED(unverified-artifact) | plausible_sql | 1.227 | 166.1 | NO |  |
| Calcite | 289 | ELAB_ERROR |  | 0.0 | 178.0 |  |  |
| Calcite | 29 | ELAB_ERROR |  | 0.0 | 65.0 |  |  |
| Calcite | 290 | INCONCLUSIVE | exhausted | 4.4207 | 328.1 |  |  |
| Calcite | 291 | INCONCLUSIVE |  | 0.0 | 288.2 |  |  |
| Calcite | 292 | ELAB_ERROR |  | 0.0 | 194.8 |  |  |
| Calcite | 293 | ELAB_ERROR |  | 0.0 | 96.7 |  |  |
| Calcite | 294 | INCONCLUSIVE | exhausted | 6.7255 | 501.8 |  |  |
| Calcite | 295 | ELAB_ERROR |  | 0.0 | 657.0 |  |  |
| Calcite | 296 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/296.lean |
| Calcite | 297 | PROVED | sql_equiv | 0.0 | 4.5 | yes | Bench/Calcite/Proven/297.lean |
| Calcite | 298 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/298.lean |
| Calcite | 299 | ELAB_ERROR |  | 0.0 | 588.5 |  |  |
| Calcite | 3 | ELAB_ERROR |  | 0.0 | 68.2 |  |  |
| Calcite | 30 | PROVED | sql_equiv | 0.0 | 4.4 | yes | Bench/Calcite/Proven/30.lean |
| Calcite | 300 | INCONCLUSIVE | exhausted | 5.3468 | 436.5 |  |  |
| Calcite | 301 | PROVED | sql_equiv | 0.0 | 4.5 | yes | Bench/Calcite/Proven/301.lean |
| Calcite | 302 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.2069 | 68.5 |  |  |
| Calcite | 303 | INCONCLUSIVE | exhausted | 1.5809 | 102.8 |  |  |
| Calcite | 304 | INCONCLUSIVE | exhausted | 0.7223 | 25.4 |  |  |
| Calcite | 305 | INCONCLUSIVE | exhausted | 6.1543 | 438.2 |  |  |
| Calcite | 306 | PROVED | sql_equiv | 0.0 | 5.1 | yes | Bench/Calcite/Proven/306.lean |
| Calcite | 307 | ELAB_ERROR |  | 0.0 | 100.5 |  |  |
| Calcite | 308 | INCONCLUSIVE | exhausted | 5.0146 | 384.0 |  |  |
| Calcite | 309 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.2788 | 27.9 |  |  |
| Calcite | 31 | INCONCLUSIVE | exhausted | 0.6547 | 17.7 |  |  |
| Calcite | 310 | INCONCLUSIVE |  | 0.0 | 187.5 |  |  |
| Calcite | 311 | INCONCLUSIVE | exhausted | 0.6887 | 22.6 |  |  |
| Calcite | 312 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/312.lean |
| Calcite | 313 | PROVED | llm | 0.3039 | 29.4 | yes | Bench/Calcite/Proven/313.lean |
| Calcite | 314 | INCONCLUSIVE | exhausted | 1.3564 | 78.0 |  |  |
| Calcite | 315 | PROVED | llm | 1.2652 | 82.4 | yes | Bench/Calcite/Proven/315.lean |
| Calcite | 316 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/316.lean |
| Calcite | 317 | INCONCLUSIVE | exhausted | 6.6862 | 499.2 |  |  |
| Calcite | 318 | INCONCLUSIVE | exhausted | 0.6693 | 17.2 |  |  |
| Calcite | 319 | ELAB_ERROR |  | 0.0 | 110.3 |  |  |
| Calcite | 32 | PROVED | sql_equiv | 0.0 | 17.3 | yes | Bench/Calcite/Proven/32.lean |
| Calcite | 320 | PROVED | llm | 0.2237 | 22.8 | yes | Bench/Calcite/Proven/320.lean |
| Calcite | 321 | INCONCLUSIVE | exhausted | 2.2653 | 172.9 |  |  |
| Calcite | 322 | ELAB_ERROR |  | 0.0 | 100.7 |  |  |
| Calcite | 323 | INCONCLUSIVE | exhausted | 0.6667 | 18.3 |  |  |
| Calcite | 324 | DISPROVED(unverified-artifact) | plausible_sql | 0.472 | 75.2 | NO |  |
| Calcite | 325 | INCONCLUSIVE | exhausted | 2.0069 | 177.0 |  |  |
| Calcite | 326 | ELAB_ERROR |  | 0.0 | 132.5 |  |  |
| Calcite | 327 | INCONCLUSIVE | exhausted | 1.0329 | 73.7 |  |  |
| Calcite | 328 | ELAB_ERROR |  | 0.0 | 159.9 |  |  |
| Calcite | 329 | PROVED | sql_equiv | 0.0 | 6.8 | yes | Bench/Calcite/Proven/329.lean |
| Calcite | 33 | INCONCLUSIVE | exhausted | 1.1715 | 66.6 |  |  |
| Calcite | 330 | INCONCLUSIVE |  | 0.0 | 140.0 |  |  |
| Calcite | 331 | INCONCLUSIVE | exhausted | 5.0262 | 437.6 |  |  |
| Calcite | 332 | ELAB_ERROR |  | 0.0 | 222.3 |  |  |
| Calcite | 333 | PROVED | sql_equiv | 0.0 | 4.8 | yes | Bench/Calcite/Proven/333.lean |
| Calcite | 334 | INCONCLUSIVE | exhausted | 2.4499 | 184.4 |  |  |
| Calcite | 335 | INCONCLUSIVE |  | 0.0 | 189.6 |  |  |
| Calcite | 336 | PROVED | sql_equiv | 0.0 | 7.1 | yes | Bench/Calcite/Proven/336.lean |
| Calcite | 337 | INCONCLUSIVE |  | 0.0 | 120.6 |  |  |
| Calcite | 338 | ELAB_ERROR |  | 0.0 | 101.2 |  |  |
| Calcite | 339 | PROVED | llm | 0.3009 | 20.1 | yes | Bench/Calcite/Proven/339.lean |
| Calcite | 34 | INCONCLUSIVE | exhausted | 0.6873 | 23.0 |  |  |
| Calcite | 340 | ELAB_ERROR |  | 0.0 | 270.4 |  |  |
| Calcite | 341 | PROVED | sql_equiv | 0.0 | 5.6 | yes | Bench/Calcite/Proven/341.lean |
| Calcite | 342 | INCONCLUSIVE | exhausted | 3.6637 | 267.3 |  |  |
| Calcite | 343 | INCONCLUSIVE | exhausted | 1.7535 | 131.8 |  |  |
| Calcite | 344 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/344.lean |
| Calcite | 345 | ELAB_ERROR |  | 0.0 | 129.1 |  |  |
| Calcite | 346 | ELAB_ERROR |  | 0.0 | 165.3 |  |  |
| Calcite | 347 | TIMEOUT |  | 0.0 | 700.3 |  |  |
| Calcite | 348 | INCONCLUSIVE |  | 0.0 | 90.6 |  |  |
| Calcite | 349 | INCONCLUSIVE | exhausted | 1.8625 | 158.1 |  |  |
| Calcite | 35 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/35.lean |
| Calcite | 350 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.6814 | 68.0 |  |  |
| Calcite | 351 | INCONCLUSIVE | exhausted | 0.6465 | 15.9 |  |  |
| Calcite | 352 | INCONCLUSIVE | exhausted | 0.7595 | 27.6 |  |  |
| Calcite | 353 | ELAB_ERROR |  | 0.0 | 85.5 |  |  |
| Calcite | 354 | INCONCLUSIVE |  | 0.0 | 254.1 |  |  |
| Calcite | 355 | ELAB_ERROR |  | 0.0 | 119.0 |  |  |
| Calcite | 356 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/356.lean |
| Calcite | 357 | INCONCLUSIVE |  | 0.0 | 262.5 |  |  |
| Calcite | 358 | ELAB_ERROR |  | 0.0 | 107.6 |  |  |
| Calcite | 359 | ELAB_ERROR |  | 0.0 | 67.8 |  |  |
| Calcite | 36 | INCONCLUSIVE |  | 0.0 | 186.4 |  |  |
| Calcite | 360 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/360.lean |
| Calcite | 361 | INCONCLUSIVE | exhausted | 0.6761 | 19.2 |  |  |
| Calcite | 362 | INCONCLUSIVE | exhausted | 4.3921 | 321.2 |  |  |
| Calcite | 363 | ELAB_ERROR |  | 0.0 | 112.4 |  |  |
| Calcite | 364 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/364.lean |
| Calcite | 365 | ELAB_ERROR |  | 0.0 | 75.8 |  |  |
| Calcite | 366 | INCONCLUSIVE |  | 0.0 | 121.5 |  |  |
| Calcite | 367 | INCONCLUSIVE | exhausted | 5.4491 | 383.8 |  |  |
| Calcite | 368 | INCONCLUSIVE |  | 0.0 | 122.7 |  |  |
| Calcite | 369 | INCONCLUSIVE | exhausted | 0.6545 | 19.5 |  |  |
| Calcite | 37 | ELAB_ERROR |  | 0.0 | 187.2 |  |  |
| Calcite | 370 | INCONCLUSIVE | exhausted | 3.5569 | 291.0 |  |  |
| Calcite | 371 | ELAB_ERROR |  | 0.0 | 99.3 |  |  |
| Calcite | 372 | ELAB_ERROR |  | 0.0 | 100.2 |  |  |
| Calcite | 373 | ELAB_ERROR |  | 0.0 | 166.3 |  |  |
| Calcite | 374 | ELAB_ERROR |  | 0.0 | 134.9 |  |  |
| Calcite | 375 | PROVED | sql_equiv | 0.0 | 4.5 | yes | Bench/Calcite/Proven/375.lean |
| Calcite | 376 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/376.lean |
| Calcite | 377 | ELAB_ERROR |  | 0.0 | 57.0 |  |  |
| Calcite | 378 | INCONCLUSIVE | exhausted | 0.6515 | 18.8 |  |  |
| Calcite | 379 | INCONCLUSIVE | exhausted | 5.3345 | 411.0 |  |  |
| Calcite | 38 | PROVED | sql_equiv | 0.0 | 4.8 | yes | Bench/Calcite/Proven/38.lean |
| Calcite | 380 | ELAB_ERROR |  | 0.0 | 67.2 |  |  |
| Calcite | 381 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.6085 | 67.5 |  |  |
| Calcite | 382 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/382.lean |
| Calcite | 383 | INCONCLUSIVE | exhausted | 0.6507 | 18.5 |  |  |
| Calcite | 384 | ELAB_ERROR |  | 0.0 | 74.6 |  |  |
| Calcite | 385 | ELAB_ERROR |  | 0.0 | 77.2 |  |  |
| Calcite | 386 | ELAB_ERROR |  | 0.0 | 76.4 |  |  |
| Calcite | 387 | PROVED | sql_equiv | 0.0 | 4.8 | yes | Bench/Calcite/Proven/387.lean |
| Calcite | 388 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.2298 | 28.9 |  |  |
| Calcite | 389 | INCONCLUSIVE | exhausted | 0.6497 | 17.4 |  |  |
| Calcite | 39 | ELAB_ERROR |  | 0.0 | 63.9 |  |  |
| Calcite | 390 | PROVED | sql_equiv | 0.0 | 5.4 | yes | Bench/Calcite/Proven/390.lean |
| Calcite | 391 | ELAB_ERROR |  | 0.0 | 405.2 |  |  |
| Calcite | 392 | INCONCLUSIVE | exhausted | 6.6337 | 534.6 |  |  |
| Calcite | 393 | INCONCLUSIVE | exhausted | 2.0044 | 136.6 |  |  |
| Calcite | 394 | PROVED | llm | 0.241 | 12.8 | yes | Bench/Calcite/Proven/394.lean |
| Calcite | 395 | ELAB_ERROR |  | 0.0 | 123.9 |  |  |
| Calcite | 396 | INCONCLUSIVE | exhausted | 0.6541 | 18.5 |  |  |
| Calcite | 397 | PROVED | sql_equiv | 0.0 | 5.7 | yes | Bench/Calcite/Proven/397.lean |
| Calcite | 4 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 1.2542 | 96.8 |  |  |
| Calcite | 40 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/40.lean |
| Calcite | 41 | ELAB_ERROR |  | 0.0 | 99.4 |  |  |
| Calcite | 42 | ELAB_ERROR |  | 0.0 | 105.0 |  |  |
| Calcite | 43 | ELAB_ERROR |  | 0.0 | 103.0 |  |  |
| Calcite | 44 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.2694 | 42.5 |  |  |
| Calcite | 45 | PROVED | llm | 0.2433 | 13.0 | yes | Bench/Calcite/Proven/45.lean |
| Calcite | 46 | ELAB_ERROR |  | 0.0 | 84.5 |  |  |
| Calcite | 47 | ELAB_ERROR |  | 0.0 | 457.7 |  |  |
| Calcite | 48 | ELAB_ERROR |  | 0.0 | 102.6 |  |  |
| Calcite | 49 | PROVED | sql_equiv | 0.0 | 5.1 | yes | Bench/Calcite/Proven/49.lean |
| Calcite | 5 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.3017 | 43.0 |  |  |
| Calcite | 50 | PROVED | llm | 0.3272 | 18.0 | yes | Bench/Calcite/Proven/50.lean |
| Calcite | 51 | INCONCLUSIVE |  | 0.0 | 35.2 |  |  |
| Calcite | 52 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.2928 | 27.6 |  |  |
| Calcite | 53 | INCONCLUSIVE |  | 0.0 | 209.6 |  |  |
| Calcite | 54 | DISPROVED(unverified-artifact) | plausible_sql | 4.4687 | 352.8 | NO |  |
| Calcite | 55 | ELAB_ERROR |  | 0.0 | 69.6 |  |  |
| Calcite | 56 | ELAB_ERROR |  | 0.0 | 67.1 |  |  |
| Calcite | 57 | PROVED | llm | 0.2475 | 19.8 | yes | Bench/Calcite/Proven/57.lean |
| Calcite | 58 | INCONCLUSIVE | exhausted | 2.4885 | 187.6 |  |  |
| Calcite | 59 | PROVED | llm | 0.2564 | 13.7 | yes | Bench/Calcite/Proven/59.lean |
| Calcite | 6 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/6.lean |
| Calcite | 60 | ELAB_ERROR |  | 0.0 | 238.8 |  |  |
| Calcite | 61 | ELAB_ERROR |  | 0.0 | 254.2 |  |  |
| Calcite | 62 | INCONCLUSIVE | exhausted | 5.1707 | 406.3 |  |  |
| Calcite | 63 | INCONCLUSIVE | exhausted | 2.7322 | 203.6 |  |  |
| Calcite | 64 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.2764 | 33.3 |  |  |
| Calcite | 65 | ELAB_ERROR |  | 0.0 | 134.2 |  |  |
| Calcite | 66 | ELAB_ERROR |  | 0.0 | 48.9 |  |  |
| Calcite | 67 | ELAB_ERROR |  | 0.0 | 151.1 |  |  |
| Calcite | 68 | PROVED | sql_equiv | 0.0 | 4.5 | yes | Bench/Calcite/Proven/68.lean |
| Calcite | 69 | ELAB_ERROR |  | 0.0 | 32.9 |  |  |
| Calcite | 7 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/7.lean |
| Calcite | 70 | ELAB_ERROR |  | 0.0 | 77.9 |  |  |
| Calcite | 71 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/71.lean |
| Calcite | 72 | INCONCLUSIVE | exhausted | 1.0972 | 107.0 |  |  |
| Calcite | 73 | INCONCLUSIVE | exhausted | 2.6564 | 174.3 |  |  |
| Calcite | 74 | INCONCLUSIVE | exhausted | 7.2219 | 519.0 |  |  |
| Calcite | 75 | ELAB_ERROR |  | 0.0 | 114.5 |  |  |
| Calcite | 76 | INCONCLUSIVE |  | 0.0 | 146.2 |  |  |
| Calcite | 77 | INCONCLUSIVE | exhausted | 5.8248 | 675.3 |  |  |
| Calcite | 78 | ELAB_ERROR |  | 0.0 | 99.6 |  |  |
| Calcite | 79 | INCONCLUSIVE |  | 0.0 | 96.4 |  |  |
| Calcite | 8 | PROVED | sql_equiv | 0.0 | 4.5 | yes | Bench/Calcite/Proven/8.lean |
| Calcite | 80 | ELAB_ERROR |  | 0.0 | 143.1 |  |  |
| Calcite | 81 | DISPROVED(unverified-artifact) | plausible_sql | 0.2575 | 29.2 | NO |  |
| Calcite | 82 | ELAB_ERROR |  | 0.0 | 55.9 |  |  |
| Calcite | 83 | PROVED | llm | 0.3804 | 28.5 | yes | Bench/Calcite/Proven/83.lean |
| Calcite | 84 | PROVED | llm | 0.8735 | 59.4 | yes | Bench/Calcite/Proven/84.lean |
| Calcite | 85 | INCONCLUSIVE | exhausted | 7.4618 | 524.2 |  |  |
| Calcite | 86 | INCONCLUSIVE | exhausted | 1.6709 | 150.3 |  |  |
| Calcite | 87 | ELAB_ERROR |  | 0.0 | 381.5 |  |  |
| Calcite | 88 | ELAB_ERROR |  | 0.0 | 39.3 |  |  |
| Calcite | 89 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Calcite/Proven/89.lean |
| Calcite | 9 | PROVED | sql_equiv | 0.0 | 4.5 | yes | Bench/Calcite/Proven/9.lean |
| Calcite | 90 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| Calcite | 91 | INCONCLUSIVE |  | 0.0 | 110.6 |  |  |
| Calcite | 92 | PROVED | llm | 1.8223 | 128.8 | yes | Bench/Calcite/Proven/92.lean |
| Calcite | 93 | INCONCLUSIVE |  | 0.0 | 51.2 |  |  |
| Calcite | 94 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.2631 | 70.0 |  |  |
| Calcite | 95 | ELAB_ERROR |  | 0.0 | 63.6 |  |  |
| Calcite | 96 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 1.406 | 157.8 |  |  |
| Calcite | 97 | INCONCLUSIVE | exhausted | 3.8781 | 297.5 |  |  |
| Calcite | 98 | ELAB_ERROR |  | 0.0 | 110.2 |  |  |
| Calcite | 99 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/Calcite/Proven/99.lean |
| CrossSkill | sf010_eq_0_1 | ELAB_ERROR |  | 0.0 | 90.0 |  |  |
| CrossSkill | sf010_eq_0_2 | ELAB_ERROR |  | 0.0 | 82.5 |  |  |
| CrossSkill | sf010_eq_0_3 | ELAB_ERROR |  | 0.0 | 71.2 |  |  |
| CrossSkill | sf010_eq_1_2 | INCONCLUSIVE | exhausted | 0.6295 | 19.8 |  |  |
| CrossSkill | sf010_eq_1_3 | INCONCLUSIVE | exhausted | 1.1245 | 66.8 |  |  |
| CrossSkill | sf010_eq_2_3 | INCONCLUSIVE | exhausted | 0.6595 | 21.7 |  |  |
| CrossSkill | sf035_eq_0_1 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/CrossSkill/Proven/sf035_eq_0_1.lean |
| CrossSkill | sf035_eq_0_2 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/CrossSkill/Proven/sf035_eq_0_2.lean |
| CrossSkill | sf035_eq_1_2 | PROVED | sql_equiv | 0.0 | 4.8 | yes | Bench/CrossSkill/Proven/sf035_eq_1_2.lean |
| CrossSkill | sf041_eq_0_1 | INCONCLUSIVE | exhausted | 0.6574 | 20.1 |  |  |
| CrossSkill | sf_bq001_eq_0_1 | ELAB_ERROR |  | 0.0 | 59.0 |  |  |
| CrossSkill | sf_bq001_eq_0_2 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq001_eq_0_3 | ELAB_ERROR |  | 0.0 | 59.9 |  |  |
| CrossSkill | sf_bq001_eq_1_2 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq001_eq_1_3 | ELAB_ERROR |  | 0.0 | 59.8 |  |  |
| CrossSkill | sf_bq001_eq_2_3 | ELAB_ERROR |  | 0.0 | 77.3 |  |  |
| CrossSkill | sf_bq002_eq_0_1 | ELAB_ERROR |  | 0.0 | 105.5 |  |  |
| CrossSkill | sf_bq002_eq_0_2 | ELAB_ERROR |  | 0.0 | 105.4 |  |  |
| CrossSkill | sf_bq002_eq_0_3 | ELAB_ERROR |  | 0.0 | 107.6 |  |  |
| CrossSkill | sf_bq002_eq_1_2 | ELAB_ERROR |  | 0.0 | 107.7 |  |  |
| CrossSkill | sf_bq002_eq_1_3 | ELAB_ERROR |  | 0.0 | 105.8 |  |  |
| CrossSkill | sf_bq002_eq_2_3 | ELAB_ERROR |  | 0.0 | 116.8 |  |  |
| CrossSkill | sf_bq003_eq_0_1 | ELAB_ERROR |  | 0.0 | 90.7 |  |  |
| CrossSkill | sf_bq003_eq_0_2 | ELAB_ERROR |  | 0.0 | 100.8 |  |  |
| CrossSkill | sf_bq003_eq_1_2 | ELAB_ERROR |  | 0.0 | 99.4 |  |  |
| CrossSkill | sf_bq004_eq_0_1 | ELAB_ERROR |  | 0.0 | 90.9 |  |  |
| CrossSkill | sf_bq004_eq_0_2 | ELAB_ERROR |  | 0.0 | 87.0 |  |  |
| CrossSkill | sf_bq004_eq_0_3 | ELAB_ERROR |  | 0.0 | 91.8 |  |  |
| CrossSkill | sf_bq004_eq_1_2 | ELAB_ERROR |  | 0.0 | 235.3 |  |  |
| CrossSkill | sf_bq004_eq_1_3 | ELAB_ERROR |  | 0.0 | 359.1 |  |  |
| CrossSkill | sf_bq004_eq_2_3 | INCONCLUSIVE | exhausted | 4.2229 | 289.6 |  |  |
| CrossSkill | sf_bq005_eq_0_1 | INCONCLUSIVE | exhausted | 0.6948 | 21.6 |  |  |
| CrossSkill | sf_bq005_eq_0_2 | INCONCLUSIVE | exhausted | 0.949 | 43.3 |  |  |
| CrossSkill | sf_bq005_eq_0_3 | INCONCLUSIVE | exhausted | 1.7327 | 102.3 |  |  |
| CrossSkill | sf_bq005_eq_1_2 | INCONCLUSIVE | exhausted | 0.7038 | 28.7 |  |  |
| CrossSkill | sf_bq005_eq_1_3 | INCONCLUSIVE | exhausted | 0.7038 | 20.5 |  |  |
| CrossSkill | sf_bq005_eq_2_3 | INCONCLUSIVE | exhausted | 1.9655 | 147.2 |  |  |
| CrossSkill | sf_bq006_eq_0_1 | INCONCLUSIVE |  | 0.0 | 292.8 |  |  |
| CrossSkill | sf_bq006_eq_0_3 | INCONCLUSIVE |  | 0.0 | 51.6 |  |  |
| CrossSkill | sf_bq006_eq_1_2 | INCONCLUSIVE |  | 0.0 | 301.4 |  |  |
| CrossSkill | sf_bq006_eq_1_3 | INCONCLUSIVE |  | 0.0 | 98.5 |  |  |
| CrossSkill | sf_bq008_eq_0_1 | ELAB_ERROR |  | 0.0 | 364.9 |  |  |
| CrossSkill | sf_bq008_eq_0_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2421 | 29.6 |  |  |
| CrossSkill | sf_bq008_eq_1_2 | ELAB_ERROR |  | 0.0 | 164.9 |  |  |
| CrossSkill | sf_bq010_eq_0_1 | INCONCLUSIVE |  | 0.0 | 80.6 |  |  |
| CrossSkill | sf_bq010_eq_0_2 | INCONCLUSIVE |  | 0.0 | 132.5 |  |  |
| CrossSkill | sf_bq010_eq_0_3 | ELAB_ERROR |  | 0.0 | 120.8 |  |  |
| CrossSkill | sf_bq010_eq_1_2 | ELAB_ERROR |  | 0.0 | 250.8 |  |  |
| CrossSkill | sf_bq010_eq_1_3 | ELAB_ERROR |  | 0.0 | 178.8 |  |  |
| CrossSkill | sf_bq010_eq_2_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2811 | 63.8 |  |  |
| CrossSkill | sf_bq011_eq_0_1 | ELAB_ERROR |  | 0.0 | 162.1 |  |  |
| CrossSkill | sf_bq011_eq_0_2 | ELAB_ERROR |  | 0.0 | 82.0 |  |  |
| CrossSkill | sf_bq011_eq_0_3 | ELAB_ERROR |  | 0.0 | 354.2 |  |  |
| CrossSkill | sf_bq011_eq_1_2 | INCONCLUSIVE |  | 0.0 | 91.9 |  |  |
| CrossSkill | sf_bq011_eq_1_3 | INCONCLUSIVE |  | 0.0 | 119.1 |  |  |
| CrossSkill | sf_bq011_eq_2_3 | ELAB_ERROR |  | 0.0 | 322.6 |  |  |
| CrossSkill | sf_bq014_eq_0_1 | TIMEOUT |  | 0.0 | 700.5 |  |  |
| CrossSkill | sf_bq015_eq_0_1 | INCONCLUSIVE |  | 0.0 | 59.0 |  |  |
| CrossSkill | sf_bq015_eq_0_2 | INCONCLUSIVE |  | 0.0 | 88.4 |  |  |
| CrossSkill | sf_bq015_eq_0_3 | INCONCLUSIVE |  | 0.0 | 93.3 |  |  |
| CrossSkill | sf_bq015_eq_1_2 | INCONCLUSIVE |  | 0.0 | 87.1 |  |  |
| CrossSkill | sf_bq015_eq_1_3 | INCONCLUSIVE |  | 0.0 | 58.7 |  |  |
| CrossSkill | sf_bq015_eq_2_3 | INCONCLUSIVE |  | 0.0 | 55.5 |  |  |
| CrossSkill | sf_bq016_eq_0_1 | INCONCLUSIVE |  | 0.0 | 268.1 |  |  |
| CrossSkill | sf_bq019_eq_0_1 | PROVED | sql_equiv | 0.0 | 13.3 | yes | Bench/CrossSkill/Proven/sf_bq019_eq_0_1.lean |
| CrossSkill | sf_bq019_eq_0_2 | INCONCLUSIVE |  | 0.0 | 141.2 |  |  |
| CrossSkill | sf_bq019_eq_0_3 | INCONCLUSIVE |  | 0.0 | 122.7 |  |  |
| CrossSkill | sf_bq019_eq_1_2 | INCONCLUSIVE |  | 0.0 | 154.0 |  |  |
| CrossSkill | sf_bq019_eq_1_3 | INCONCLUSIVE |  | 0.0 | 114.9 |  |  |
| CrossSkill | sf_bq019_eq_2_3 | PROVED | sql_equiv | 0.0 | 5.5 | yes | Bench/CrossSkill/Proven/sf_bq019_eq_2_3.lean |
| CrossSkill | sf_bq020_eq_0_1 | INCONCLUSIVE | exhausted | 4.2129 | 369.6 |  |  |
| CrossSkill | sf_bq020_eq_0_2 | INCONCLUSIVE | exhausted | 4.2665 | 336.5 |  |  |
| CrossSkill | sf_bq020_eq_0_3 | INCONCLUSIVE | exhausted | 5.6483 | 476.7 |  |  |
| CrossSkill | sf_bq020_eq_1_2 | PROVED | sql_equiv | 0.0 | 17.3 | yes | Bench/CrossSkill/Proven/sf_bq020_eq_1_2.lean |
| CrossSkill | sf_bq020_eq_1_3 | INCONCLUSIVE | exhausted | 1.6765 | 143.3 |  |  |
| CrossSkill | sf_bq020_eq_2_3 | INCONCLUSIVE | exhausted | 3.0148 | 270.1 |  |  |
| CrossSkill | sf_bq021_eq_0_1 | ELAB_ERROR |  | 0.0 | 79.3 |  |  |
| CrossSkill | sf_bq021_eq_0_2 | ELAB_ERROR |  | 0.0 | 113.3 |  |  |
| CrossSkill | sf_bq021_eq_1_2 | ELAB_ERROR |  | 0.0 | 70.5 |  |  |
| CrossSkill | sf_bq022_eq_0_2 | ELAB_ERROR |  | 0.0 | 70.0 |  |  |
| CrossSkill | sf_bq023_eq_0_1 | ELAB_ERROR |  | 0.0 | 151.5 |  |  |
| CrossSkill | sf_bq023_eq_0_2 | ELAB_ERROR |  | 0.0 | 178.9 |  |  |
| CrossSkill | sf_bq023_eq_1_2 | ELAB_ERROR |  | 0.0 | 124.5 |  |  |
| CrossSkill | sf_bq027_eq_0_2 | PROVED | sql_equiv | 0.0 | 5.2 | yes | Bench/CrossSkill/Proven/sf_bq027_eq_0_2.lean |
| CrossSkill | sf_bq030_eq_0_1 | ELAB_ERROR |  | 0.0 | 72.5 |  |  |
| CrossSkill | sf_bq030_eq_0_3 | ELAB_ERROR |  | 0.0 | 71.4 |  |  |
| CrossSkill | sf_bq030_eq_1_3 | ELAB_ERROR |  | 0.0 | 73.9 |  |  |
| CrossSkill | sf_bq032_eq_1_2 | ELAB_ERROR |  | 0.0 | 84.9 |  |  |
| CrossSkill | sf_bq032_eq_1_3 | ELAB_ERROR |  | 0.0 | 84.5 |  |  |
| CrossSkill | sf_bq032_eq_2_3 | ELAB_ERROR |  | 0.0 | 83.8 |  |  |
| CrossSkill | sf_bq035_eq_0_1 | INCONCLUSIVE |  | 0.0 | 54.9 |  |  |
| CrossSkill | sf_bq035_eq_0_2 | INCONCLUSIVE |  | 0.0 | 67.2 |  |  |
| CrossSkill | sf_bq035_eq_1_2 | INCONCLUSIVE |  | 0.0 | 47.4 |  |  |
| CrossSkill | sf_bq036_eq_0_1 | INCONCLUSIVE |  | 0.0 | 73.7 |  |  |
| CrossSkill | sf_bq036_eq_0_2 | INCONCLUSIVE |  | 0.0 | 64.2 |  |  |
| CrossSkill | sf_bq036_eq_1_2 | INCONCLUSIVE |  | 0.0 | 65.3 |  |  |
| CrossSkill | sf_bq039_eq_0_1 | ELAB_ERROR |  | 0.0 | 58.3 |  |  |
| CrossSkill | sf_bq039_eq_0_2 | ELAB_ERROR |  | 0.0 | 38.9 |  |  |
| CrossSkill | sf_bq039_eq_0_3 | ELAB_ERROR |  | 0.0 | 29.3 |  |  |
| CrossSkill | sf_bq039_eq_1_2 | ELAB_ERROR |  | 0.0 | 493.0 |  |  |
| CrossSkill | sf_bq039_eq_1_3 | INCONCLUSIVE |  | 0.0 | 372.9 |  |  |
| CrossSkill | sf_bq039_eq_2_3 | PROVED | sql_equiv | 0.0 | 8.8 | yes | Bench/CrossSkill/Proven/sf_bq039_eq_2_3.lean |
| CrossSkill | sf_bq040_eq_0_1 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq040_eq_0_2 | ELAB_ERROR |  | 0.0 | 356.6 |  |  |
| CrossSkill | sf_bq040_eq_0_3 | ELAB_ERROR |  | 0.0 | 81.4 |  |  |
| CrossSkill | sf_bq040_eq_1_2 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq040_eq_1_3 | ELAB_ERROR |  | 0.0 | 382.2 |  |  |
| CrossSkill | sf_bq040_eq_2_3 | ELAB_ERROR |  | 0.0 | 123.5 |  |  |
| CrossSkill | sf_bq041_eq_0_1 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2174 | 27.6 |  |  |
| CrossSkill | sf_bq041_eq_0_2 | ELAB_ERROR |  | 0.0 | 61.8 |  |  |
| CrossSkill | sf_bq041_eq_1_2 | ELAB_ERROR |  | 0.0 | 280.3 |  |  |
| CrossSkill | sf_bq042_eq_0_1 | ELAB_ERROR |  | 0.0 | 142.7 |  |  |
| CrossSkill | sf_bq042_eq_0_2 | ELAB_ERROR |  | 0.0 | 121.5 |  |  |
| CrossSkill | sf_bq042_eq_0_3 | ELAB_ERROR |  | 0.0 | 78.6 |  |  |
| CrossSkill | sf_bq042_eq_1_2 | ELAB_ERROR |  | 0.0 | 133.6 |  |  |
| CrossSkill | sf_bq042_eq_1_3 | ELAB_ERROR |  | 0.0 | 182.1 |  |  |
| CrossSkill | sf_bq042_eq_2_3 | INCONCLUSIVE |  | 0.0 | 221.4 |  |  |
| CrossSkill | sf_bq044_eq_0_1 | ELAB_ERROR |  | 0.0 | 136.3 |  |  |
| CrossSkill | sf_bq044_eq_0_2 | ELAB_ERROR |  | 0.0 | 113.1 |  |  |
| CrossSkill | sf_bq044_eq_0_3 | ELAB_ERROR |  | 0.0 | 101.7 |  |  |
| CrossSkill | sf_bq044_eq_1_2 | INCONCLUSIVE | exhausted | 0.7966 | 29.1 |  |  |
| CrossSkill | sf_bq044_eq_1_3 | INCONCLUSIVE | exhausted | 0.7288 | 24.5 |  |  |
| CrossSkill | sf_bq044_eq_2_3 | INCONCLUSIVE | exhausted | 0.6412 | 17.1 |  |  |
| CrossSkill | sf_bq045_eq_0_1 | PROVED | sql_equiv | 0.0 | 21.1 | yes | Bench/CrossSkill/Proven/sf_bq045_eq_0_1.lean |
| CrossSkill | sf_bq045_eq_0_2 | INCONCLUSIVE |  | 0.0 | 152.1 |  |  |
| CrossSkill | sf_bq045_eq_0_3 | INCONCLUSIVE |  | 0.0 | 154.8 |  |  |
| CrossSkill | sf_bq045_eq_1_2 | INCONCLUSIVE |  | 0.0 | 164.9 |  |  |
| CrossSkill | sf_bq045_eq_1_3 | INCONCLUSIVE |  | 0.0 | 131.5 |  |  |
| CrossSkill | sf_bq045_eq_2_3 | INCONCLUSIVE |  | 0.0 | 168.2 |  |  |
| CrossSkill | sf_bq046_eq_0_1 | ELAB_ERROR |  | 0.0 | 73.5 |  |  |
| CrossSkill | sf_bq046_eq_0_2 | ELAB_ERROR |  | 0.0 | 73.8 |  |  |
| CrossSkill | sf_bq046_eq_0_3 | ELAB_ERROR |  | 0.0 | 71.5 |  |  |
| CrossSkill | sf_bq046_eq_1_2 | ELAB_ERROR |  | 0.0 | 70.6 |  |  |
| CrossSkill | sf_bq046_eq_1_3 | INCONCLUSIVE | exhausted | 0.8608 | 45.1 |  |  |
| CrossSkill | sf_bq046_eq_2_3 | ELAB_ERROR |  | 0.0 | 70.4 |  |  |
| CrossSkill | sf_bq047_eq_0_1 | ELAB_ERROR |  | 0.0 | 283.2 |  |  |
| CrossSkill | sf_bq047_eq_0_2 | ELAB_ERROR |  | 0.0 | 287.1 |  |  |
| CrossSkill | sf_bq047_eq_1_2 | ELAB_ERROR |  | 0.0 | 231.2 |  |  |
| CrossSkill | sf_bq048_eq_0_1 | ELAB_ERROR |  | 0.0 | 127.8 |  |  |
| CrossSkill | sf_bq048_eq_0_2 | ELAB_ERROR |  | 0.0 | 57.3 |  |  |
| CrossSkill | sf_bq048_eq_0_3 | ELAB_ERROR |  | 0.0 | 97.5 |  |  |
| CrossSkill | sf_bq048_eq_1_2 | ELAB_ERROR |  | 0.0 | 94.9 |  |  |
| CrossSkill | sf_bq048_eq_1_3 | ELAB_ERROR |  | 0.0 | 85.8 |  |  |
| CrossSkill | sf_bq048_eq_2_3 | ELAB_ERROR |  | 0.0 | 85.8 |  |  |
| CrossSkill | sf_bq049_eq_0_1 | INCONCLUSIVE |  | 0.0 | 77.7 |  |  |
| CrossSkill | sf_bq049_eq_0_2 | ELAB_ERROR |  | 0.0 | 124.2 |  |  |
| CrossSkill | sf_bq049_eq_0_3 | ELAB_ERROR |  | 0.0 | 402.0 |  |  |
| CrossSkill | sf_bq049_eq_1_2 | ELAB_ERROR |  | 0.0 | 208.8 |  |  |
| CrossSkill | sf_bq049_eq_1_3 | ELAB_ERROR |  | 0.0 | 466.8 |  |  |
| CrossSkill | sf_bq049_eq_2_3 | ELAB_ERROR |  | 0.0 | 87.4 |  |  |
| CrossSkill | sf_bq051_eq_0_1 | ELAB_ERROR |  | 0.0 | 137.6 |  |  |
| CrossSkill | sf_bq051_eq_0_2 | ELAB_ERROR |  | 0.0 | 141.4 |  |  |
| CrossSkill | sf_bq051_eq_1_2 | ELAB_ERROR |  | 0.0 | 130.3 |  |  |
| CrossSkill | sf_bq053_eq_0_1 | INCONCLUSIVE |  | 0.0 | 103.7 |  |  |
| CrossSkill | sf_bq053_eq_0_2 | INCONCLUSIVE |  | 0.0 | 97.1 |  |  |
| CrossSkill | sf_bq053_eq_0_3 | INCONCLUSIVE |  | 0.0 | 95.1 |  |  |
| CrossSkill | sf_bq053_eq_1_2 | INCONCLUSIVE |  | 0.0 | 103.8 |  |  |
| CrossSkill | sf_bq053_eq_1_3 | INCONCLUSIVE |  | 0.0 | 149.8 |  |  |
| CrossSkill | sf_bq053_eq_2_3 | INCONCLUSIVE |  | 0.0 | 99.2 |  |  |
| CrossSkill | sf_bq054_eq_0_1 | INCONCLUSIVE | exhausted | 3.5386 | 293.1 |  |  |
| CrossSkill | sf_bq054_eq_0_2 | INCONCLUSIVE |  | 0.0 | 38.9 |  |  |
| CrossSkill | sf_bq054_eq_1_2 | ELAB_ERROR |  | 0.0 | 273.3 |  |  |
| CrossSkill | sf_bq055_eq_0_1 | INCONCLUSIVE |  | 0.0 | 68.4 |  |  |
| CrossSkill | sf_bq055_eq_0_2 | ELAB_ERROR |  | 0.0 | 187.8 |  |  |
| CrossSkill | sf_bq055_eq_0_3 | INCONCLUSIVE |  | 0.0 | 80.6 |  |  |
| CrossSkill | sf_bq055_eq_1_2 | INCONCLUSIVE |  | 0.0 | 48.6 |  |  |
| CrossSkill | sf_bq055_eq_1_3 | INCONCLUSIVE |  | 0.0 | 48.2 |  |  |
| CrossSkill | sf_bq055_eq_2_3 | INCONCLUSIVE |  | 0.0 | 80.1 |  |  |
| CrossSkill | sf_bq056_eq_0_1 | ELAB_ERROR |  | 0.0 | 122.3 |  |  |
| CrossSkill | sf_bq056_eq_0_2 | ELAB_ERROR |  | 0.0 | 127.4 |  |  |
| CrossSkill | sf_bq056_eq_0_3 | ELAB_ERROR |  | 0.0 | 98.6 |  |  |
| CrossSkill | sf_bq056_eq_1_2 | INCONCLUSIVE | exhausted | 0.6478 | 16.6 |  |  |
| CrossSkill | sf_bq056_eq_1_3 | INCONCLUSIVE | exhausted | 0.6921 | 20.3 |  |  |
| CrossSkill | sf_bq056_eq_2_3 | INCONCLUSIVE | exhausted | 0.6548 | 15.5 |  |  |
| CrossSkill | sf_bq059_eq_0_1 | ELAB_ERROR |  | 0.0 | 69.3 |  |  |
| CrossSkill | sf_bq059_eq_0_2 | INCONCLUSIVE |  | 0.0 | 81.4 |  |  |
| CrossSkill | sf_bq059_eq_0_3 | ELAB_ERROR |  | 0.0 | 269.2 |  |  |
| CrossSkill | sf_bq059_eq_1_2 | ELAB_ERROR |  | 0.0 | 59.5 |  |  |
| CrossSkill | sf_bq059_eq_1_3 | ELAB_ERROR |  | 0.0 | 92.8 |  |  |
| CrossSkill | sf_bq059_eq_2_3 | ELAB_ERROR |  | 0.0 | 186.3 |  |  |
| CrossSkill | sf_bq060_eq_0_1 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.1999 | 78.4 |  |  |
| CrossSkill | sf_bq060_eq_0_2 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/CrossSkill/Proven/sf_bq060_eq_0_2.lean |
| CrossSkill | sf_bq060_eq_0_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2177 | 147.5 |  |  |
| CrossSkill | sf_bq060_eq_1_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2153 | 120.8 |  |  |
| CrossSkill | sf_bq060_eq_1_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2117 | 135.6 |  |  |
| CrossSkill | sf_bq060_eq_2_3 | INCONCLUSIVE |  | 0.0 | 70.4 |  |  |
| CrossSkill | sf_bq061_eq_0_1 | ELAB_ERROR |  | 0.0 | 75.2 |  |  |
| CrossSkill | sf_bq061_eq_0_2 | ELAB_ERROR |  | 0.0 | 72.7 |  |  |
| CrossSkill | sf_bq061_eq_0_3 | ELAB_ERROR |  | 0.0 | 72.7 |  |  |
| CrossSkill | sf_bq061_eq_1_2 | ELAB_ERROR |  | 0.0 | 71.8 |  |  |
| CrossSkill | sf_bq061_eq_1_3 | ELAB_ERROR |  | 0.0 | 73.0 |  |  |
| CrossSkill | sf_bq061_eq_2_3 | ELAB_ERROR |  | 0.0 | 73.5 |  |  |
| CrossSkill | sf_bq062_eq_0_1 | PROVED | sql_equiv | 0.0 | 5.5 | yes | Bench/CrossSkill/Proven/sf_bq062_eq_0_1.lean |
| CrossSkill | sf_bq064_eq_0_1 | ELAB_ERROR |  | 0.0 | 86.0 |  |  |
| CrossSkill | sf_bq064_eq_0_2 | ELAB_ERROR |  | 0.0 | 85.1 |  |  |
| CrossSkill | sf_bq064_eq_0_3 | ELAB_ERROR |  | 0.0 | 83.4 |  |  |
| CrossSkill | sf_bq064_eq_1_2 | ELAB_ERROR |  | 0.0 | 164.0 |  |  |
| CrossSkill | sf_bq064_eq_1_3 | ELAB_ERROR |  | 0.0 | 153.8 |  |  |
| CrossSkill | sf_bq064_eq_2_3 | ELAB_ERROR |  | 0.0 | 294.0 |  |  |
| CrossSkill | sf_bq065_eq_1_2 | ELAB_ERROR |  | 0.0 | 73.5 |  |  |
| CrossSkill | sf_bq065_eq_1_3 | ELAB_ERROR |  | 0.0 | 7.6 |  |  |
| CrossSkill | sf_bq065_eq_2_3 | ELAB_ERROR |  | 0.0 | 6.9 |  |  |
| CrossSkill | sf_bq067_eq_0_1 | ELAB_ERROR |  | 0.0 | 74.9 |  |  |
| CrossSkill | sf_bq067_eq_0_2 | ELAB_ERROR |  | 0.0 | 77.4 |  |  |
| CrossSkill | sf_bq067_eq_0_3 | ELAB_ERROR |  | 0.0 | 73.8 |  |  |
| CrossSkill | sf_bq067_eq_1_2 | ELAB_ERROR |  | 0.0 | 75.5 |  |  |
| CrossSkill | sf_bq067_eq_1_3 | ELAB_ERROR |  | 0.0 | 74.8 |  |  |
| CrossSkill | sf_bq067_eq_2_3 | ELAB_ERROR |  | 0.0 | 77.3 |  |  |
| CrossSkill | sf_bq071_eq_0_1 | ELAB_ERROR |  | 0.0 | 84.3 |  |  |
| CrossSkill | sf_bq071_eq_0_2 | ELAB_ERROR |  | 0.0 | 84.3 |  |  |
| CrossSkill | sf_bq071_eq_1_2 | ELAB_ERROR |  | 0.0 | 84.3 |  |  |
| CrossSkill | sf_bq073_eq_0_1 | ELAB_ERROR |  | 0.0 | 73.3 |  |  |
| CrossSkill | sf_bq073_eq_0_2 | ELAB_ERROR |  | 0.0 | 72.6 |  |  |
| CrossSkill | sf_bq073_eq_1_2 | ELAB_ERROR |  | 0.0 | 72.4 |  |  |
| CrossSkill | sf_bq074_eq_0_1 | ELAB_ERROR |  | 0.0 | 72.0 |  |  |
| CrossSkill | sf_bq074_eq_0_2 | ELAB_ERROR |  | 0.0 | 72.2 |  |  |
| CrossSkill | sf_bq074_eq_0_3 | ELAB_ERROR |  | 0.0 | 72.7 |  |  |
| CrossSkill | sf_bq074_eq_1_2 | ELAB_ERROR |  | 0.0 | 72.1 |  |  |
| CrossSkill | sf_bq074_eq_1_3 | ELAB_ERROR |  | 0.0 | 73.0 |  |  |
| CrossSkill | sf_bq074_eq_2_3 | ELAB_ERROR |  | 0.0 | 75.7 |  |  |
| CrossSkill | sf_bq075_eq_0_1 | ELAB_ERROR |  | 0.0 | 86.4 |  |  |
| CrossSkill | sf_bq075_eq_0_2 | ELAB_ERROR |  | 0.0 | 101.7 |  |  |
| CrossSkill | sf_bq075_eq_0_3 | ELAB_ERROR |  | 0.0 | 34.9 |  |  |
| CrossSkill | sf_bq075_eq_1_2 | PROVED | sql_equiv | 0.0 | 13.0 | yes | Bench/CrossSkill/Proven/sf_bq075_eq_1_2.lean |
| CrossSkill | sf_bq075_eq_1_3 | INCONCLUSIVE |  | 0.0 | 23.3 |  |  |
| CrossSkill | sf_bq075_eq_2_3 | INCONCLUSIVE |  | 0.0 | 26.5 |  |  |
| CrossSkill | sf_bq076_eq_0_1 | INCONCLUSIVE | exhausted | 1.9939 | 153.7 |  |  |
| CrossSkill | sf_bq078_eq_0_1 | PROVED | sql_equiv | 0.0 | 5.7 | yes | Bench/CrossSkill/Proven/sf_bq078_eq_0_1.lean |
| CrossSkill | sf_bq078_eq_0_2 | PROVED | sql_equiv | 0.0 | 5.6 | yes | Bench/CrossSkill/Proven/sf_bq078_eq_0_2.lean |
| CrossSkill | sf_bq078_eq_1_2 | PROVED | sql_equiv | 0.0 | 5.8 | yes | Bench/CrossSkill/Proven/sf_bq078_eq_1_2.lean |
| CrossSkill | sf_bq079_eq_0_1 | INCONCLUSIVE |  | 0.0 | 33.6 |  |  |
| CrossSkill | sf_bq079_eq_0_2 | INCONCLUSIVE |  | 0.0 | 43.1 |  |  |
| CrossSkill | sf_bq079_eq_0_3 | INCONCLUSIVE |  | 0.0 | 83.1 |  |  |
| CrossSkill | sf_bq079_eq_1_2 | INCONCLUSIVE |  | 0.0 | 20.4 |  |  |
| CrossSkill | sf_bq079_eq_1_3 | INCONCLUSIVE |  | 0.0 | 45.0 |  |  |
| CrossSkill | sf_bq079_eq_2_3 | INCONCLUSIVE |  | 0.0 | 95.6 |  |  |
| CrossSkill | sf_bq080_eq_0_1 | INCONCLUSIVE |  | 0.0 | 127.2 |  |  |
| CrossSkill | sf_bq080_eq_0_2 | INCONCLUSIVE |  | 0.0 | 90.6 |  |  |
| CrossSkill | sf_bq080_eq_1_2 | INCONCLUSIVE |  | 0.0 | 175.5 |  |  |
| CrossSkill | sf_bq084_eq_0_1 | INCONCLUSIVE | exhausted | 0.7017 | 31.2 |  |  |
| CrossSkill | sf_bq084_eq_0_2 | INCONCLUSIVE | exhausted | 0.7617 | 35.6 |  |  |
| CrossSkill | sf_bq084_eq_0_3 | INCONCLUSIVE | exhausted | 0.6725 | 24.2 |  |  |
| CrossSkill | sf_bq084_eq_1_2 | INCONCLUSIVE | exhausted | 0.6651 | 25.9 |  |  |
| CrossSkill | sf_bq084_eq_1_3 | INCONCLUSIVE | exhausted | 0.7465 | 33.1 |  |  |
| CrossSkill | sf_bq084_eq_2_3 | INCONCLUSIVE | exhausted | 0.6595 | 27.2 |  |  |
| CrossSkill | sf_bq085_eq_0_1 | PROVED | sql_equiv | 0.0 | 10.6 | yes | Bench/CrossSkill/Proven/sf_bq085_eq_0_1.lean |
| CrossSkill | sf_bq085_eq_0_2 | INCONCLUSIVE |  | 0.0 | 65.0 |  |  |
| CrossSkill | sf_bq085_eq_0_3 | INCONCLUSIVE |  | 0.0 | 41.4 |  |  |
| CrossSkill | sf_bq085_eq_1_2 | INCONCLUSIVE |  | 0.0 | 66.3 |  |  |
| CrossSkill | sf_bq085_eq_1_3 | INCONCLUSIVE |  | 0.0 | 49.3 |  |  |
| CrossSkill | sf_bq085_eq_2_3 | INCONCLUSIVE |  | 0.0 | 66.2 |  |  |
| CrossSkill | sf_bq086_eq_0_1 | ELAB_ERROR |  | 0.0 | 72.2 |  |  |
| CrossSkill | sf_bq086_eq_0_2 | ELAB_ERROR |  | 0.0 | 72.0 |  |  |
| CrossSkill | sf_bq086_eq_0_3 | ELAB_ERROR |  | 0.0 | 71.8 |  |  |
| CrossSkill | sf_bq086_eq_1_2 | ELAB_ERROR |  | 0.0 | 71.8 |  |  |
| CrossSkill | sf_bq086_eq_1_3 | ELAB_ERROR |  | 0.0 | 73.7 |  |  |
| CrossSkill | sf_bq086_eq_2_3 | ELAB_ERROR |  | 0.0 | 72.5 |  |  |
| CrossSkill | sf_bq090_eq_0_1 | INCONCLUSIVE | exhausted | 0.662 | 18.8 |  |  |
| CrossSkill | sf_bq092_eq_0_1 | INCONCLUSIVE |  | 0.0 | 109.4 |  |  |
| CrossSkill | sf_bq094_eq_0_1 | ELAB_ERROR |  | 0.0 | 128.2 |  |  |
| CrossSkill | sf_bq094_eq_0_2 | INCONCLUSIVE | exhausted | 2.0202 | 140.1 |  |  |
| CrossSkill | sf_bq094_eq_1_2 | INCONCLUSIVE | exhausted | 0.6126 | 15.4 |  |  |
| CrossSkill | sf_bq095_eq_0_1 | ELAB_ERROR |  | 0.0 | 94.1 |  |  |
| CrossSkill | sf_bq095_eq_0_2 | INCONCLUSIVE |  | 0.0 | 41.0 |  |  |
| CrossSkill | sf_bq095_eq_0_3 | ELAB_ERROR |  | 0.0 | 44.0 |  |  |
| CrossSkill | sf_bq095_eq_1_2 | ELAB_ERROR |  | 0.0 | 42.8 |  |  |
| CrossSkill | sf_bq095_eq_1_3 | INCONCLUSIVE | exhausted | 0.6278 | 17.3 |  |  |
| CrossSkill | sf_bq095_eq_2_3 | INCONCLUSIVE | exhausted | 1.7156 | 105.8 |  |  |
| CrossSkill | sf_bq096_eq_1_2 | PROVED | sql_equiv | 0.0 | 19.3 | yes | Bench/CrossSkill/Proven/sf_bq096_eq_1_2.lean |
| CrossSkill | sf_bq098_eq_0_1 | ELAB_ERROR |  | 0.0 | 66.8 |  |  |
| CrossSkill | sf_bq098_eq_0_2 | ELAB_ERROR |  | 0.0 | 66.7 |  |  |
| CrossSkill | sf_bq098_eq_0_3 | ELAB_ERROR |  | 0.0 | 68.5 |  |  |
| CrossSkill | sf_bq098_eq_1_2 | INCONCLUSIVE |  | 0.0 | 139.1 |  |  |
| CrossSkill | sf_bq098_eq_1_3 | INCONCLUSIVE |  | 0.0 | 188.3 |  |  |
| CrossSkill | sf_bq098_eq_2_3 | INCONCLUSIVE | exhausted | 5.2129 | 425.2 |  |  |
| CrossSkill | sf_bq100_eq_1_2 | ELAB_ERROR |  | 0.0 | 80.7 |  |  |
| CrossSkill | sf_bq100_eq_2_3 | INCONCLUSIVE |  | 0.0 | 62.7 |  |  |
| CrossSkill | sf_bq103_eq_0_1 | INCONCLUSIVE | exhausted | 0.6663 | 35.2 |  |  |
| CrossSkill | sf_bq105_eq_0_1 | INCONCLUSIVE |  | 0.0 | 138.0 |  |  |
| CrossSkill | sf_bq105_eq_0_2 | ELAB_ERROR |  | 0.0 | 112.8 |  |  |
| CrossSkill | sf_bq105_eq_0_3 | ELAB_ERROR |  | 0.0 | 85.8 |  |  |
| CrossSkill | sf_bq105_eq_1_2 | ELAB_ERROR |  | 0.0 | 100.8 |  |  |
| CrossSkill | sf_bq105_eq_1_3 | INCONCLUSIVE |  | 0.0 | 116.8 |  |  |
| CrossSkill | sf_bq105_eq_2_3 | ELAB_ERROR |  | 0.0 | 49.6 |  |  |
| CrossSkill | sf_bq107_eq_0_1 | DISPROVED(unverified-artifact) | plausible_sql | 0.3358 | 43.3 | NO |  |
| CrossSkill | sf_bq107_eq_0_2 | ELAB_ERROR |  | 0.0 | 84.2 |  |  |
| CrossSkill | sf_bq107_eq_0_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.4688 | 53.8 | NO |  |
| CrossSkill | sf_bq107_eq_1_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.2755 | 21.6 | NO |  |
| CrossSkill | sf_bq107_eq_1_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.3523 | 51.0 |  |  |
| CrossSkill | sf_bq107_eq_2_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.2767 | 29.7 | NO |  |
| CrossSkill | sf_bq108_eq_0_1 | ELAB_ERROR |  | 0.0 | 81.8 |  |  |
| CrossSkill | sf_bq108_eq_0_2 | ELAB_ERROR |  | 0.0 | 72.9 |  |  |
| CrossSkill | sf_bq108_eq_1_2 | ELAB_ERROR |  | 0.0 | 72.9 |  |  |
| CrossSkill | sf_bq112_eq_0_1 | ELAB_ERROR |  | 0.0 | 99.5 |  |  |
| CrossSkill | sf_bq112_eq_0_2 | ELAB_ERROR |  | 0.0 | 120.4 |  |  |
| CrossSkill | sf_bq112_eq_0_3 | ELAB_ERROR |  | 0.0 | 99.4 |  |  |
| CrossSkill | sf_bq112_eq_1_2 | ELAB_ERROR |  | 0.0 | 71.5 |  |  |
| CrossSkill | sf_bq112_eq_1_3 | ELAB_ERROR |  | 0.0 | 71.5 |  |  |
| CrossSkill | sf_bq112_eq_2_3 | ELAB_ERROR |  | 0.0 | 75.6 |  |  |
| CrossSkill | sf_bq113_eq_0_1 | ELAB_ERROR |  | 0.0 | 74.9 |  |  |
| CrossSkill | sf_bq113_eq_0_2 | ELAB_ERROR |  | 0.0 | 76.2 |  |  |
| CrossSkill | sf_bq113_eq_0_3 | INCONCLUSIVE |  | 0.0 | 147.5 |  |  |
| CrossSkill | sf_bq113_eq_1_2 | ELAB_ERROR |  | 0.0 | 73.5 |  |  |
| CrossSkill | sf_bq113_eq_1_3 | ELAB_ERROR |  | 0.0 | 73.1 |  |  |
| CrossSkill | sf_bq113_eq_2_3 | INCONCLUSIVE |  | 0.0 | 194.4 |  |  |
| CrossSkill | sf_bq114_eq_0_1 | INCONCLUSIVE |  | 0.0 | 58.2 |  |  |
| CrossSkill | sf_bq114_eq_0_2 | ELAB_ERROR |  | 0.0 | 116.4 |  |  |
| CrossSkill | sf_bq114_eq_0_3 | INCONCLUSIVE |  | 0.0 | 32.8 |  |  |
| CrossSkill | sf_bq114_eq_1_2 | ELAB_ERROR |  | 0.0 | 87.8 |  |  |
| CrossSkill | sf_bq114_eq_1_3 | INCONCLUSIVE |  | 0.0 | 54.1 |  |  |
| CrossSkill | sf_bq114_eq_2_3 | ELAB_ERROR |  | 0.0 | 98.9 |  |  |
| CrossSkill | sf_bq115_eq_0_1 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2208 | 48.3 |  |  |
| CrossSkill | sf_bq115_eq_0_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.3301 | 75.8 | NO |  |
| CrossSkill | sf_bq115_eq_0_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.3287 | 78.7 | NO |  |
| CrossSkill | sf_bq115_eq_1_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.2406 | 45.5 | NO |  |
| CrossSkill | sf_bq115_eq_1_3 | DISPROVED(unverified-artifact) | plausible_sql | 1.8227 | 173.2 | NO |  |
| CrossSkill | sf_bq115_eq_2_3 | INCONCLUSIVE | exhausted | 0.6855 | 19.2 |  |  |
| CrossSkill | sf_bq117_eq_0_1 | INCONCLUSIVE | exhausted | 0.6992 | 33.5 |  |  |
| CrossSkill | sf_bq117_eq_0_2 | INCONCLUSIVE | exhausted | 0.6936 | 29.3 |  |  |
| CrossSkill | sf_bq117_eq_0_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.5586 | 59.5 |  |  |
| CrossSkill | sf_bq117_eq_1_2 | INCONCLUSIVE | exhausted | 0.7229 | 45.4 |  |  |
| CrossSkill | sf_bq117_eq_1_3 | INCONCLUSIVE | exhausted | 0.7088 | 33.4 |  |  |
| CrossSkill | sf_bq117_eq_2_3 | INCONCLUSIVE | exhausted | 0.6998 | 32.1 |  |  |
| CrossSkill | sf_bq118_eq_0_1 | ELAB_ERROR |  | 0.0 | 155.8 |  |  |
| CrossSkill | sf_bq118_eq_0_2 | ELAB_ERROR |  | 0.0 | 140.1 |  |  |
| CrossSkill | sf_bq118_eq_0_3 | ELAB_ERROR |  | 0.0 | 76.4 |  |  |
| CrossSkill | sf_bq118_eq_1_2 | DISPROVED | plausible_sql | 0.3063 | 28.8 | yes(sqlglot-inconclusive) | Bench/CrossSkill/CounterExample/sf_bq118_eq_1_2.lean |
| CrossSkill | sf_bq118_eq_1_3 | ELAB_ERROR |  | 0.0 | 116.9 |  |  |
| CrossSkill | sf_bq118_eq_2_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.2968 | 48.8 | NO |  |
| CrossSkill | sf_bq119_eq_1_2 | ELAB_ERROR |  | 0.0 | 120.8 |  |  |
| CrossSkill | sf_bq119_eq_1_3 | ELAB_ERROR |  | 0.0 | 135.5 |  |  |
| CrossSkill | sf_bq119_eq_2_3 | ELAB_ERROR |  | 0.0 | 116.1 |  |  |
| CrossSkill | sf_bq120_eq_0_1 | ELAB_ERROR |  | 0.0 | 84.2 |  |  |
| CrossSkill | sf_bq120_eq_0_2 | ELAB_ERROR |  | 0.0 | 84.6 |  |  |
| CrossSkill | sf_bq120_eq_0_3 | INCONCLUSIVE |  | 0.0 | 58.3 |  |  |
| CrossSkill | sf_bq120_eq_1_2 | ELAB_ERROR |  | 0.0 | 82.4 |  |  |
| CrossSkill | sf_bq120_eq_1_3 | ELAB_ERROR |  | 0.0 | 84.4 |  |  |
| CrossSkill | sf_bq120_eq_2_3 | ELAB_ERROR |  | 0.0 | 85.0 |  |  |
| CrossSkill | sf_bq123_eq_0_1 | INCONCLUSIVE | exhausted | 0.779 | 32.3 |  |  |
| CrossSkill | sf_bq123_eq_0_2 | INCONCLUSIVE | exhausted | 0.6793 | 18.7 |  |  |
| CrossSkill | sf_bq123_eq_0_3 | ELAB_ERROR |  | 0.0 | 6.7 |  |  |
| CrossSkill | sf_bq123_eq_1_2 | INCONCLUSIVE | exhausted | 0.6291 | 15.1 |  |  |
| CrossSkill | sf_bq123_eq_1_3 | ELAB_ERROR |  | 0.0 | 6.8 |  |  |
| CrossSkill | sf_bq123_eq_2_3 | ELAB_ERROR |  | 0.0 | 5.9 |  |  |
| CrossSkill | sf_bq124_eq_0_1 | INCONCLUSIVE | exhausted | 0.646 | 14.6 |  |  |
| CrossSkill | sf_bq124_eq_0_2 | INCONCLUSIVE | exhausted | 0.699 | 21.5 |  |  |
| CrossSkill | sf_bq124_eq_0_3 | INCONCLUSIVE | exhausted | 0.6642 | 16.5 |  |  |
| CrossSkill | sf_bq124_eq_1_2 | INCONCLUSIVE | exhausted | 0.656 | 17.0 |  |  |
| CrossSkill | sf_bq124_eq_1_3 | INCONCLUSIVE | exhausted | 0.6082 | 15.3 |  |  |
| CrossSkill | sf_bq124_eq_2_3 | INCONCLUSIVE | exhausted | 0.654 | 18.5 |  |  |
| CrossSkill | sf_bq126_eq_0_1 | PROVED | sql_equiv | 0.0 | 13.1 | yes | Bench/CrossSkill/Proven/sf_bq126_eq_0_1.lean |
| CrossSkill | sf_bq126_eq_0_2 | INCONCLUSIVE |  | 0.0 | 83.2 |  |  |
| CrossSkill | sf_bq126_eq_0_3 | INCONCLUSIVE |  | 0.0 | 67.5 |  |  |
| CrossSkill | sf_bq126_eq_1_2 | INCONCLUSIVE |  | 0.0 | 60.3 |  |  |
| CrossSkill | sf_bq126_eq_1_3 | INCONCLUSIVE |  | 0.0 | 109.0 |  |  |
| CrossSkill | sf_bq126_eq_2_3 | INCONCLUSIVE |  | 0.0 | 55.4 |  |  |
| CrossSkill | sf_bq131_eq_0_1 | ELAB_ERROR |  | 0.0 | 116.6 |  |  |
| CrossSkill | sf_bq131_eq_0_2 | ELAB_ERROR |  | 0.0 | 84.1 |  |  |
| CrossSkill | sf_bq131_eq_0_3 | ELAB_ERROR |  | 0.0 | 88.1 |  |  |
| CrossSkill | sf_bq131_eq_1_2 | INCONCLUSIVE |  | 0.0 | 46.8 |  |  |
| CrossSkill | sf_bq131_eq_1_3 | INCONCLUSIVE |  | 0.0 | 58.4 |  |  |
| CrossSkill | sf_bq131_eq_2_3 | INCONCLUSIVE |  | 0.0 | 56.8 |  |  |
| CrossSkill | sf_bq135_eq_1_2 | INCONCLUSIVE | exhausted | 1.8115 | 110.0 |  |  |
| CrossSkill | sf_bq136_eq_0_1 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.463 | 32.4 |  |  |
| CrossSkill | sf_bq136_eq_0_2 | INCONCLUSIVE | exhausted | 0.6857 | 19.2 |  |  |
| CrossSkill | sf_bq136_eq_0_3 | INCONCLUSIVE | exhausted | 0.6545 | 24.7 |  |  |
| CrossSkill | sf_bq136_eq_1_2 | INCONCLUSIVE | exhausted | 0.6937 | 20.4 |  |  |
| CrossSkill | sf_bq136_eq_1_3 | INCONCLUSIVE | exhausted | 0.6615 | 25.3 |  |  |
| CrossSkill | sf_bq136_eq_2_3 | INCONCLUSIVE | exhausted | 0.6503 | 24.2 |  |  |
| CrossSkill | sf_bq137_eq_0_1 | INCONCLUSIVE | exhausted | 2.0456 | 184.0 |  |  |
| CrossSkill | sf_bq137_eq_0_2 | ELAB_ERROR |  | 0.0 | 129.9 |  |  |
| CrossSkill | sf_bq137_eq_1_2 | ELAB_ERROR |  | 0.0 | 126.2 |  |  |
| CrossSkill | sf_bq141_eq_0_1 | ELAB_ERROR |  | 0.0 | 181.9 |  |  |
| CrossSkill | sf_bq144_eq_0_1 | ELAB_ERROR |  | 0.0 | 69.4 |  |  |
| CrossSkill | sf_bq144_eq_0_2 | INCONCLUSIVE |  | 0.0 | 179.6 |  |  |
| CrossSkill | sf_bq144_eq_1_2 | PROVED | sql_equiv | 0.0 | 64.9 | yes | Bench/CrossSkill/Proven/sf_bq144_eq_1_2.lean |
| CrossSkill | sf_bq148_eq_0_1 | INCONCLUSIVE | exhausted | 2.5152 | 169.5 |  |  |
| CrossSkill | sf_bq151_eq_0_1 | ELAB_ERROR |  | 0.0 | 72.7 |  |  |
| CrossSkill | sf_bq151_eq_0_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2283 | 92.1 |  |  |
| CrossSkill | sf_bq151_eq_0_3 | ELAB_ERROR |  | 0.0 | 72.8 |  |  |
| CrossSkill | sf_bq151_eq_1_2 | ELAB_ERROR |  | 0.0 | 75.0 |  |  |
| CrossSkill | sf_bq151_eq_1_3 | ELAB_ERROR |  | 0.0 | 73.6 |  |  |
| CrossSkill | sf_bq151_eq_2_3 | ELAB_ERROR |  | 0.0 | 76.0 |  |  |
| CrossSkill | sf_bq154_eq_0_1 | ELAB_ERROR |  | 0.0 | 72.2 |  |  |
| CrossSkill | sf_bq154_eq_0_2 | ELAB_ERROR |  | 0.0 | 73.0 |  |  |
| CrossSkill | sf_bq154_eq_0_3 | ELAB_ERROR |  | 0.0 | 72.8 |  |  |
| CrossSkill | sf_bq154_eq_1_2 | ELAB_ERROR |  | 0.0 | 72.5 |  |  |
| CrossSkill | sf_bq154_eq_1_3 | ELAB_ERROR |  | 0.0 | 73.5 |  |  |
| CrossSkill | sf_bq154_eq_2_3 | ELAB_ERROR |  | 0.0 | 72.8 |  |  |
| CrossSkill | sf_bq156_eq_0_1 | DISPROVED(unverified-artifact) | plausible_sql | 0.359 | 60.4 | NO |  |
| CrossSkill | sf_bq156_eq_0_2 | ELAB_ERROR |  | 0.0 | 230.7 |  |  |
| CrossSkill | sf_bq156_eq_0_3 | ELAB_ERROR |  | 0.0 | 126.6 |  |  |
| CrossSkill | sf_bq156_eq_1_2 | ELAB_ERROR |  | 0.0 | 76.8 |  |  |
| CrossSkill | sf_bq156_eq_1_3 | ELAB_ERROR |  | 0.0 | 129.3 |  |  |
| CrossSkill | sf_bq156_eq_2_3 | DISPROVED | plausible_sql | 0.8441 | 51.3 | yes(sqlglot-inconclusive) | Bench/CrossSkill/CounterExample/sf_bq156_eq_2_3.lean |
| CrossSkill | sf_bq157_eq_0_1 | ELAB_ERROR |  | 0.0 | 216.3 |  |  |
| CrossSkill | sf_bq157_eq_0_2 | ELAB_ERROR |  | 0.0 | 226.5 |  |  |
| CrossSkill | sf_bq157_eq_0_3 | ELAB_ERROR |  | 0.0 | 225.7 |  |  |
| CrossSkill | sf_bq157_eq_1_2 | ELAB_ERROR |  | 0.0 | 240.9 |  |  |
| CrossSkill | sf_bq157_eq_1_3 | INCONCLUSIVE |  | 0.0 | 171.2 |  |  |
| CrossSkill | sf_bq157_eq_2_3 | DISPROVED | plausible_sql | 0.5503 | 57.1 | yes(sqlglot-inconclusive) | Bench/CrossSkill/CounterExample/sf_bq157_eq_2_3.lean |
| CrossSkill | sf_bq160_eq_0_1 | INCONCLUSIVE |  | 0.0 | 62.4 |  |  |
| CrossSkill | sf_bq160_eq_0_2 | INCONCLUSIVE |  | 0.0 | 105.4 |  |  |
| CrossSkill | sf_bq160_eq_0_3 | INCONCLUSIVE |  | 0.0 | 168.4 |  |  |
| CrossSkill | sf_bq160_eq_1_2 | INCONCLUSIVE |  | 0.0 | 76.2 |  |  |
| CrossSkill | sf_bq160_eq_1_3 | INCONCLUSIVE |  | 0.0 | 119.1 |  |  |
| CrossSkill | sf_bq160_eq_2_3 | INCONCLUSIVE |  | 0.0 | 256.3 |  |  |
| CrossSkill | sf_bq161_eq_0_1 | ELAB_ERROR |  | 0.0 | 70.2 |  |  |
| CrossSkill | sf_bq161_eq_0_2 | ELAB_ERROR |  | 0.0 | 71.9 |  |  |
| CrossSkill | sf_bq161_eq_1_2 | ELAB_ERROR |  | 0.0 | 72.9 |  |  |
| CrossSkill | sf_bq162_eq_0_1 | INCONCLUSIVE |  | 0.0 | 92.7 |  |  |
| CrossSkill | sf_bq162_eq_0_2 | ELAB_ERROR |  | 0.0 | 76.6 |  |  |
| CrossSkill | sf_bq162_eq_0_3 | INCONCLUSIVE |  | 0.0 | 105.4 |  |  |
| CrossSkill | sf_bq162_eq_1_2 | INCONCLUSIVE |  | 0.0 | 99.3 |  |  |
| CrossSkill | sf_bq162_eq_1_3 | INCONCLUSIVE |  | 0.0 | 87.5 |  |  |
| CrossSkill | sf_bq162_eq_2_3 | ELAB_ERROR |  | 0.0 | 80.6 |  |  |
| CrossSkill | sf_bq169_eq_0_1 | ELAB_ERROR |  | 0.0 | 112.4 |  |  |
| CrossSkill | sf_bq169_eq_0_2 | ELAB_ERROR |  | 0.0 | 72.9 |  |  |
| CrossSkill | sf_bq169_eq_0_3 | ELAB_ERROR |  | 0.0 | 110.1 |  |  |
| CrossSkill | sf_bq169_eq_1_2 | ELAB_ERROR |  | 0.0 | 109.6 |  |  |
| CrossSkill | sf_bq169_eq_1_3 | PROVED | sql_equiv | 0.0 | 17.6 | yes | Bench/CrossSkill/Proven/sf_bq169_eq_1_3.lean |
| CrossSkill | sf_bq169_eq_2_3 | ELAB_ERROR |  | 0.0 | 111.8 |  |  |
| CrossSkill | sf_bq170_eq_0_1 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq171_eq_0_1 | ELAB_ERROR |  | 0.0 | 84.0 |  |  |
| CrossSkill | sf_bq171_eq_0_2 | PROVED | sql_equiv | 0.0 | 8.2 | yes | Bench/CrossSkill/Proven/sf_bq171_eq_0_2.lean |
| CrossSkill | sf_bq171_eq_0_3 | ELAB_ERROR |  | 0.0 | 205.4 |  |  |
| CrossSkill | sf_bq171_eq_1_2 | ELAB_ERROR |  | 0.0 | 105.6 |  |  |
| CrossSkill | sf_bq171_eq_1_3 | ELAB_ERROR |  | 0.0 | 194.7 |  |  |
| CrossSkill | sf_bq171_eq_2_3 | ELAB_ERROR |  | 0.0 | 252.9 |  |  |
| CrossSkill | sf_bq172_eq_0_1 | PROVED | sql_equiv | 0.0 | 5.2 | yes | Bench/CrossSkill/Proven/sf_bq172_eq_0_1.lean |
| CrossSkill | sf_bq172_eq_0_2 | ELAB_ERROR |  | 0.0 | 43.1 |  |  |
| CrossSkill | sf_bq172_eq_0_3 | ELAB_ERROR |  | 0.0 | 174.2 |  |  |
| CrossSkill | sf_bq172_eq_1_2 | ELAB_ERROR |  | 0.0 | 59.6 |  |  |
| CrossSkill | sf_bq172_eq_1_3 | ELAB_ERROR |  | 0.0 | 138.9 |  |  |
| CrossSkill | sf_bq172_eq_2_3 | ELAB_ERROR |  | 0.0 | 36.9 |  |  |
| CrossSkill | sf_bq175_eq_0_1 | DISPROVED(unverified-artifact) | plausible_sql | 0.5559 | 109.0 | NO |  |
| CrossSkill | sf_bq177_eq_0_1 | PROVED | sql_equiv | 0.0 | 16.0 | yes | Bench/CrossSkill/Proven/sf_bq177_eq_0_1.lean |
| CrossSkill | sf_bq177_eq_0_2 | ELAB_ERROR |  | 0.0 | 66.1 |  |  |
| CrossSkill | sf_bq177_eq_0_3 | ELAB_ERROR |  | 0.0 | 130.1 |  |  |
| CrossSkill | sf_bq177_eq_1_2 | ELAB_ERROR |  | 0.0 | 119.8 |  |  |
| CrossSkill | sf_bq177_eq_1_3 | ELAB_ERROR |  | 0.0 | 79.2 |  |  |
| CrossSkill | sf_bq177_eq_2_3 | ELAB_ERROR |  | 0.0 | 111.7 |  |  |
| CrossSkill | sf_bq181_eq_0_1 | INCONCLUSIVE |  | 0.0 | 191.8 |  |  |
| CrossSkill | sf_bq181_eq_0_2 | INCONCLUSIVE |  | 0.0 | 308.9 |  |  |
| CrossSkill | sf_bq181_eq_0_3 | INCONCLUSIVE |  | 0.0 | 189.0 |  |  |
| CrossSkill | sf_bq181_eq_1_2 | INCONCLUSIVE |  | 0.0 | 180.8 |  |  |
| CrossSkill | sf_bq181_eq_1_3 | INCONCLUSIVE |  | 0.0 | 191.0 |  |  |
| CrossSkill | sf_bq181_eq_2_3 | INCONCLUSIVE |  | 0.0 | 210.8 |  |  |
| CrossSkill | sf_bq184_eq_0_1 | ELAB_ERROR |  | 0.0 | 107.2 |  |  |
| CrossSkill | sf_bq184_eq_0_2 | ELAB_ERROR |  | 0.0 | 107.9 |  |  |
| CrossSkill | sf_bq184_eq_0_3 | ELAB_ERROR |  | 0.0 | 107.6 |  |  |
| CrossSkill | sf_bq184_eq_1_2 | ELAB_ERROR |  | 0.0 | 109.8 |  |  |
| CrossSkill | sf_bq184_eq_1_3 | ELAB_ERROR |  | 0.0 | 109.9 |  |  |
| CrossSkill | sf_bq184_eq_2_3 | ELAB_ERROR |  | 0.0 | 108.7 |  |  |
| CrossSkill | sf_bq185_eq_0_1 | ELAB_ERROR |  | 0.0 | 163.1 |  |  |
| CrossSkill | sf_bq185_eq_0_2 | ELAB_ERROR |  | 0.0 | 89.8 |  |  |
| CrossSkill | sf_bq185_eq_0_3 | ELAB_ERROR |  | 0.0 | 79.0 |  |  |
| CrossSkill | sf_bq185_eq_1_2 | ELAB_ERROR |  | 0.0 | 131.2 |  |  |
| CrossSkill | sf_bq185_eq_1_3 | ELAB_ERROR |  | 0.0 | 119.0 |  |  |
| CrossSkill | sf_bq185_eq_2_3 | ELAB_ERROR |  | 0.0 | 90.9 |  |  |
| CrossSkill | sf_bq186_eq_0_1 | DISPROVED(unverified-artifact) | plausible_sql | 0.443 | 57.6 | NO |  |
| CrossSkill | sf_bq186_eq_0_2 | INCONCLUSIVE |  | 0.0 | 45.9 |  |  |
| CrossSkill | sf_bq186_eq_1_2 | INCONCLUSIVE |  | 0.0 | 37.0 |  |  |
| CrossSkill | sf_bq188_eq_0_1 | INCONCLUSIVE |  | 0.0 | 75.8 |  |  |
| CrossSkill | sf_bq188_eq_0_2 | INCONCLUSIVE |  | 0.0 | 309.7 |  |  |
| CrossSkill | sf_bq188_eq_0_3 | ELAB_ERROR |  | 0.0 | 92.6 |  |  |
| CrossSkill | sf_bq188_eq_1_2 | INCONCLUSIVE |  | 0.0 | 69.6 |  |  |
| CrossSkill | sf_bq188_eq_1_3 | ELAB_ERROR |  | 0.0 | 139.7 |  |  |
| CrossSkill | sf_bq188_eq_2_3 | ELAB_ERROR |  | 0.0 | 87.5 |  |  |
| CrossSkill | sf_bq189_eq_0_1 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq192_eq_0_1 | INCONCLUSIVE |  | 0.0 | 55.3 |  |  |
| CrossSkill | sf_bq194_eq_1_2 | INCONCLUSIVE | exhausted | 0.6653 | 19.5 |  |  |
| CrossSkill | sf_bq194_eq_1_3 | INCONCLUSIVE | exhausted | 0.8279 | 35.2 |  |  |
| CrossSkill | sf_bq194_eq_2_3 | INCONCLUSIVE | exhausted | 0.6857 | 19.7 |  |  |
| CrossSkill | sf_bq195_eq_0_1 | INCONCLUSIVE | exhausted | 0.6818 | 24.6 |  |  |
| CrossSkill | sf_bq195_eq_0_2 | INCONCLUSIVE | exhausted | 0.6764 | 22.4 |  |  |
| CrossSkill | sf_bq195_eq_0_3 | INCONCLUSIVE | exhausted | 0.6544 | 19.9 |  |  |
| CrossSkill | sf_bq195_eq_1_2 | INCONCLUSIVE | exhausted | 0.6616 | 19.7 |  |  |
| CrossSkill | sf_bq195_eq_1_3 | INCONCLUSIVE | exhausted | 0.6594 | 19.9 |  |  |
| CrossSkill | sf_bq195_eq_2_3 | INCONCLUSIVE | exhausted | 0.6676 | 21.8 |  |  |
| CrossSkill | sf_bq197_eq_0_1 | INCONCLUSIVE |  | 0.0 | 62.2 |  |  |
| CrossSkill | sf_bq198_eq_0_1 | ELAB_ERROR |  | 0.0 | 69.8 |  |  |
| CrossSkill | sf_bq198_eq_0_2 | ELAB_ERROR |  | 0.0 | 67.8 |  |  |
| CrossSkill | sf_bq198_eq_0_3 | ELAB_ERROR |  | 0.0 | 67.6 |  |  |
| CrossSkill | sf_bq198_eq_1_2 | PROVED | sql_equiv | 0.0 | 7.3 | yes | Bench/CrossSkill/Proven/sf_bq198_eq_1_2.lean |
| CrossSkill | sf_bq198_eq_1_3 | PROVED | sql_equiv | 0.0 | 7.3 | yes | Bench/CrossSkill/Proven/sf_bq198_eq_1_3.lean |
| CrossSkill | sf_bq198_eq_2_3 | PROVED | sql_equiv | 0.0 | 4.9 | yes | Bench/CrossSkill/Proven/sf_bq198_eq_2_3.lean |
| CrossSkill | sf_bq200_eq_0_1 | ELAB_ERROR |  | 0.0 | 82.5 |  |  |
| CrossSkill | sf_bq202_eq_0_1 | INCONCLUSIVE | exhausted | 0.6654 | 18.0 |  |  |
| CrossSkill | sf_bq202_eq_0_2 | ELAB_ERROR |  | 0.0 | 69.9 |  |  |
| CrossSkill | sf_bq202_eq_1_2 | ELAB_ERROR |  | 0.0 | 93.4 |  |  |
| CrossSkill | sf_bq203_eq_0_1 | INCONCLUSIVE |  | 0.0 | 42.6 |  |  |
| CrossSkill | sf_bq207_eq_0_1 | ELAB_ERROR |  | 0.0 | 68.6 |  |  |
| CrossSkill | sf_bq208_eq_0_1 | ELAB_ERROR |  | 0.0 | 88.5 |  |  |
| CrossSkill | sf_bq208_eq_0_2 | ELAB_ERROR |  | 0.0 | 50.7 |  |  |
| CrossSkill | sf_bq208_eq_0_3 | ELAB_ERROR |  | 0.0 | 82.4 |  |  |
| CrossSkill | sf_bq208_eq_1_2 | ELAB_ERROR |  | 0.0 | 65.5 |  |  |
| CrossSkill | sf_bq208_eq_1_3 | ELAB_ERROR |  | 0.0 | 164.3 |  |  |
| CrossSkill | sf_bq208_eq_2_3 | ELAB_ERROR |  | 0.0 | 62.1 |  |  |
| CrossSkill | sf_bq212_eq_1_2 | INCONCLUSIVE |  | 0.0 | 99.9 |  |  |
| CrossSkill | sf_bq214_eq_0_1 | ELAB_ERROR |  | 0.0 | 78.2 |  |  |
| CrossSkill | sf_bq214_eq_0_2 | ELAB_ERROR |  | 0.0 | 75.9 |  |  |
| CrossSkill | sf_bq214_eq_1_2 | INCONCLUSIVE | exhausted | 0.7539 | 36.6 |  |  |
| CrossSkill | sf_bq217_eq_0_1 | INCONCLUSIVE | exhausted | 0.6483 | 15.7 |  |  |
| CrossSkill | sf_bq218_eq_0_1 | ELAB_ERROR |  | 0.0 | 89.2 |  |  |
| CrossSkill | sf_bq220_eq_0_1 | ELAB_ERROR |  | 0.0 | 84.4 |  |  |
| CrossSkill | sf_bq220_eq_0_2 | ELAB_ERROR |  | 0.0 | 80.8 |  |  |
| CrossSkill | sf_bq220_eq_0_3 | ELAB_ERROR |  | 0.0 | 81.5 |  |  |
| CrossSkill | sf_bq220_eq_1_2 | ELAB_ERROR |  | 0.0 | 161.4 |  |  |
| CrossSkill | sf_bq220_eq_1_3 | ELAB_ERROR |  | 0.0 | 86.9 |  |  |
| CrossSkill | sf_bq220_eq_2_3 | ELAB_ERROR |  | 0.0 | 196.2 |  |  |
| CrossSkill | sf_bq225_eq_0_1 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq225_eq_0_2 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq225_eq_0_3 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq225_eq_1_2 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq225_eq_1_3 | TIMEOUT |  | 0.0 | 700.3 |  |  |
| CrossSkill | sf_bq225_eq_2_3 | INCONCLUSIVE | exhausted | 4.0892 | 333.3 |  |  |
| CrossSkill | sf_bq226_eq_0_1 | PROVED | sql_equiv | 0.0 | 14.6 | yes | Bench/CrossSkill/Proven/sf_bq226_eq_0_1.lean |
| CrossSkill | sf_bq226_eq_0_2 | INCONCLUSIVE |  | 0.0 | 107.4 |  |  |
| CrossSkill | sf_bq226_eq_1_2 | INCONCLUSIVE |  | 0.0 | 56.6 |  |  |
| CrossSkill | sf_bq227_eq_0_1 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq227_eq_0_2 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq227_eq_0_3 | TIMEOUT |  | 0.0 | 700.3 |  |  |
| CrossSkill | sf_bq227_eq_1_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.5811 | 117.0 | NO |  |
| CrossSkill | sf_bq227_eq_1_3 | ELAB_ERROR |  | 0.0 | 242.3 |  |  |
| CrossSkill | sf_bq227_eq_2_3 | INCONCLUSIVE |  | 0.0 | 93.7 |  |  |
| CrossSkill | sf_bq229_eq_0_1 | INCONCLUSIVE |  | 0.0 | 22.5 |  |  |
| CrossSkill | sf_bq229_eq_0_2 | INCONCLUSIVE |  | 0.0 | 82.4 |  |  |
| CrossSkill | sf_bq229_eq_0_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.338 | 115.2 |  |  |
| CrossSkill | sf_bq229_eq_1_2 | INCONCLUSIVE | exhausted | 2.8284 | 294.2 |  |  |
| CrossSkill | sf_bq229_eq_1_3 | INCONCLUSIVE |  | 0.0 | 21.4 |  |  |
| CrossSkill | sf_bq229_eq_2_3 | INCONCLUSIVE |  | 0.0 | 51.3 |  |  |
| CrossSkill | sf_bq230_eq_0_1 | TIMEOUT |  | 0.0 | 701.9 |  |  |
| CrossSkill | sf_bq230_eq_0_2 | ELAB_ERROR |  | 0.0 | 165.7 |  |  |
| CrossSkill | sf_bq230_eq_1_2 | ELAB_ERROR |  | 0.0 | 84.9 |  |  |
| CrossSkill | sf_bq232_eq_0_1 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/CrossSkill/Proven/sf_bq232_eq_0_1.lean |
| CrossSkill | sf_bq235_eq_0_1 | INCONCLUSIVE |  | 0.0 | 38.5 |  |  |
| CrossSkill | sf_bq235_eq_0_2 | INCONCLUSIVE |  | 0.0 | 36.0 |  |  |
| CrossSkill | sf_bq235_eq_0_3 | PROVED | sql_equiv | 0.0 | 5.5 | yes | Bench/CrossSkill/Proven/sf_bq235_eq_0_3.lean |
| CrossSkill | sf_bq235_eq_1_2 | INCONCLUSIVE |  | 0.0 | 48.2 |  |  |
| CrossSkill | sf_bq235_eq_1_3 | INCONCLUSIVE |  | 0.0 | 47.6 |  |  |
| CrossSkill | sf_bq235_eq_2_3 | INCONCLUSIVE |  | 0.0 | 28.6 |  |  |
| CrossSkill | sf_bq247_eq_0_1 | INCONCLUSIVE |  | 0.0 | 140.3 |  |  |
| CrossSkill | sf_bq247_eq_0_2 | INCONCLUSIVE |  | 0.0 | 78.9 |  |  |
| CrossSkill | sf_bq247_eq_0_3 | INCONCLUSIVE |  | 0.0 | 108.5 |  |  |
| CrossSkill | sf_bq247_eq_1_2 | INCONCLUSIVE | exhausted | 1.3551 | 271.1 |  |  |
| CrossSkill | sf_bq247_eq_1_3 | PROVED | sql_equiv | 0.0 | 5.9 | yes | Bench/CrossSkill/Proven/sf_bq247_eq_1_3.lean |
| CrossSkill | sf_bq247_eq_2_3 | INCONCLUSIVE | exhausted | 1.469 | 276.2 |  |  |
| CrossSkill | sf_bq251_eq_0_1 | ELAB_ERROR |  | 0.0 | 162.0 |  |  |
| CrossSkill | sf_bq251_eq_0_2 | INCONCLUSIVE |  | 0.0 | 57.9 |  |  |
| CrossSkill | sf_bq251_eq_0_3 | INCONCLUSIVE |  | 0.0 | 109.9 |  |  |
| CrossSkill | sf_bq251_eq_1_2 | ELAB_ERROR |  | 0.0 | 136.6 |  |  |
| CrossSkill | sf_bq251_eq_1_3 | ELAB_ERROR |  | 0.0 | 128.4 |  |  |
| CrossSkill | sf_bq251_eq_2_3 | INCONCLUSIVE |  | 0.0 | 85.9 |  |  |
| CrossSkill | sf_bq253_eq_0_1 | INCONCLUSIVE | exhausted | 0.652 | 23.6 |  |  |
| CrossSkill | sf_bq258_eq_0_1 | INCONCLUSIVE | exhausted | 3.324 | 236.3 |  |  |
| CrossSkill | sf_bq258_eq_0_2 | INCONCLUSIVE |  | 0.0 | 49.3 |  |  |
| CrossSkill | sf_bq258_eq_1_2 | ELAB_ERROR |  | 0.0 | 189.8 |  |  |
| CrossSkill | sf_bq259_eq_0_1 | INCONCLUSIVE | exhausted | 0.6846 | 21.7 |  |  |
| CrossSkill | sf_bq259_eq_0_2 | INCONCLUSIVE | exhausted | 0.6568 | 17.1 |  |  |
| CrossSkill | sf_bq259_eq_1_2 | INCONCLUSIVE | exhausted | 0.6664 | 20.4 |  |  |
| CrossSkill | sf_bq261_eq_0_1 | ELAB_ERROR |  | 0.0 | 98.1 |  |  |
| CrossSkill | sf_bq261_eq_0_2 | ELAB_ERROR |  | 0.0 | 97.6 |  |  |
| CrossSkill | sf_bq261_eq_0_3 | ELAB_ERROR |  | 0.0 | 96.7 |  |  |
| CrossSkill | sf_bq261_eq_1_2 | INCONCLUSIVE | exhausted | 3.4138 | 260.0 |  |  |
| CrossSkill | sf_bq261_eq_1_3 | PROVED | llm | 0.9354 | 139.0 | yes | Bench/CrossSkill/Proven/sf_bq261_eq_1_3.lean |
| CrossSkill | sf_bq261_eq_2_3 | INCONCLUSIVE | exhausted | 2.926 | 220.0 |  |  |
| CrossSkill | sf_bq262_eq_0_1 | ELAB_ERROR |  | 0.0 | 116.8 |  |  |
| CrossSkill | sf_bq262_eq_0_2 | INCONCLUSIVE | exhausted | 0.8404 | 49.9 |  |  |
| CrossSkill | sf_bq262_eq_0_3 | INCONCLUSIVE | exhausted | 0.7777 | 48.4 |  |  |
| CrossSkill | sf_bq262_eq_1_2 | ELAB_ERROR |  | 0.0 | 39.8 |  |  |
| CrossSkill | sf_bq262_eq_1_3 | ELAB_ERROR |  | 0.0 | 76.0 |  |  |
| CrossSkill | sf_bq262_eq_2_3 | INCONCLUSIVE | exhausted | 0.7872 | 46.8 |  |  |
| CrossSkill | sf_bq266_eq_0_1 | PROVED | sql_equiv | 0.0 | 8.1 | yes | Bench/CrossSkill/Proven/sf_bq266_eq_0_1.lean |
| CrossSkill | sf_bq266_eq_0_2 | INCONCLUSIVE |  | 0.0 | 35.1 |  |  |
| CrossSkill | sf_bq266_eq_0_3 | INCONCLUSIVE |  | 0.0 | 74.4 |  |  |
| CrossSkill | sf_bq266_eq_1_2 | INCONCLUSIVE |  | 0.0 | 35.7 |  |  |
| CrossSkill | sf_bq266_eq_1_3 | INCONCLUSIVE |  | 0.0 | 146.4 |  |  |
| CrossSkill | sf_bq266_eq_2_3 | INCONCLUSIVE |  | 0.0 | 34.5 |  |  |
| CrossSkill | sf_bq268_eq_0_1 | ELAB_ERROR |  | 0.0 | 145.3 |  |  |
| CrossSkill | sf_bq268_eq_0_2 | ELAB_ERROR |  | 0.0 | 148.5 |  |  |
| CrossSkill | sf_bq268_eq_0_3 | ELAB_ERROR |  | 0.0 | 145.6 |  |  |
| CrossSkill | sf_bq268_eq_1_2 | ELAB_ERROR |  | 0.0 | 284.4 |  |  |
| CrossSkill | sf_bq268_eq_1_3 | ELAB_ERROR |  | 0.0 | 367.8 |  |  |
| CrossSkill | sf_bq268_eq_2_3 | ELAB_ERROR |  | 0.0 | 364.3 |  |  |
| CrossSkill | sf_bq269_eq_0_1 | ELAB_ERROR |  | 0.0 | 177.4 |  |  |
| CrossSkill | sf_bq269_eq_0_2 | ELAB_ERROR |  | 0.0 | 182.8 |  |  |
| CrossSkill | sf_bq269_eq_0_3 | ELAB_ERROR |  | 0.0 | 86.3 |  |  |
| CrossSkill | sf_bq269_eq_1_2 | ELAB_ERROR |  | 0.0 | 165.9 |  |  |
| CrossSkill | sf_bq269_eq_1_3 | ELAB_ERROR |  | 0.0 | 197.4 |  |  |
| CrossSkill | sf_bq269_eq_2_3 | ELAB_ERROR |  | 0.0 | 125.8 |  |  |
| CrossSkill | sf_bq270_eq_0_1 | ELAB_ERROR |  | 0.0 | 106.1 |  |  |
| CrossSkill | sf_bq270_eq_0_2 | ELAB_ERROR |  | 0.0 | 90.8 |  |  |
| CrossSkill | sf_bq270_eq_1_2 | ELAB_ERROR |  | 0.0 | 92.2 |  |  |
| CrossSkill | sf_bq272_eq_0_1 | PROVED | sql_equiv | 0.0 | 5.7 | yes | Bench/CrossSkill/Proven/sf_bq272_eq_0_1.lean |
| CrossSkill | sf_bq272_eq_0_2 | INCONCLUSIVE | exhausted | 3.3029 | 230.2 |  |  |
| CrossSkill | sf_bq272_eq_1_2 | ELAB_ERROR |  | 0.0 | 99.4 |  |  |
| CrossSkill | sf_bq278_eq_0_1 | INCONCLUSIVE |  | 0.0 | 112.9 |  |  |
| CrossSkill | sf_bq278_eq_0_2 | INCONCLUSIVE |  | 0.0 | 45.3 |  |  |
| CrossSkill | sf_bq278_eq_0_3 | ELAB_ERROR |  | 0.0 | 93.0 |  |  |
| CrossSkill | sf_bq278_eq_1_2 | INCONCLUSIVE |  | 0.0 | 55.1 |  |  |
| CrossSkill | sf_bq278_eq_1_3 | INCONCLUSIVE |  | 0.0 | 159.8 |  |  |
| CrossSkill | sf_bq278_eq_2_3 | INCONCLUSIVE |  | 0.0 | 59.3 |  |  |
| CrossSkill | sf_bq279_eq_0_1 | PROVED | sql_equiv | 0.0 | 5.6 | yes | Bench/CrossSkill/Proven/sf_bq279_eq_0_1.lean |
| CrossSkill | sf_bq279_eq_0_2 | PROVED | sql_equiv | 0.0 | 5.6 | yes | Bench/CrossSkill/Proven/sf_bq279_eq_0_2.lean |
| CrossSkill | sf_bq279_eq_0_3 | PROVED | sql_equiv | 0.0 | 5.7 | yes | Bench/CrossSkill/Proven/sf_bq279_eq_0_3.lean |
| CrossSkill | sf_bq279_eq_1_2 | PROVED | sql_equiv | 0.0 | 5.8 | yes | Bench/CrossSkill/Proven/sf_bq279_eq_1_2.lean |
| CrossSkill | sf_bq279_eq_1_3 | PROVED | sql_equiv | 0.0 | 5.7 | yes | Bench/CrossSkill/Proven/sf_bq279_eq_1_3.lean |
| CrossSkill | sf_bq279_eq_2_3 | PROVED | sql_equiv | 0.0 | 5.6 | yes | Bench/CrossSkill/Proven/sf_bq279_eq_2_3.lean |
| CrossSkill | sf_bq280_eq_0_1 | ELAB_ERROR |  | 0.0 | 75.9 |  |  |
| CrossSkill | sf_bq280_eq_0_2 | INCONCLUSIVE |  | 0.0 | 39.2 |  |  |
| CrossSkill | sf_bq280_eq_1_2 | INCONCLUSIVE | exhausted | 3.0699 | 211.9 |  |  |
| CrossSkill | sf_bq281_eq_1_2 | INCONCLUSIVE | exhausted | 4.5486 | 360.2 |  |  |
| CrossSkill | sf_bq282_eq_0_1 | INCONCLUSIVE | exhausted | 1.2332 | 99.1 |  |  |
| CrossSkill | sf_bq282_eq_0_2 | ELAB_ERROR |  | 0.0 | 114.4 |  |  |
| CrossSkill | sf_bq282_eq_1_2 | ELAB_ERROR |  | 0.0 | 99.0 |  |  |
| CrossSkill | sf_bq283_eq_0_1 | INCONCLUSIVE |  | 0.0 | 71.4 |  |  |
| CrossSkill | sf_bq283_eq_0_2 | INCONCLUSIVE |  | 0.0 | 48.6 |  |  |
| CrossSkill | sf_bq283_eq_0_3 | PROVED | sql_equiv | 0.0 | 6.9 | yes | Bench/CrossSkill/Proven/sf_bq283_eq_0_3.lean |
| CrossSkill | sf_bq283_eq_1_2 | INCONCLUSIVE |  | 0.0 | 44.6 |  |  |
| CrossSkill | sf_bq283_eq_1_3 | INCONCLUSIVE |  | 0.0 | 97.0 |  |  |
| CrossSkill | sf_bq283_eq_2_3 | INCONCLUSIVE |  | 0.0 | 43.9 |  |  |
| CrossSkill | sf_bq284_eq_0_1 | INCONCLUSIVE |  | 0.0 | 27.5 |  |  |
| CrossSkill | sf_bq284_eq_0_2 | INCONCLUSIVE |  | 0.0 | 33.6 |  |  |
| CrossSkill | sf_bq284_eq_0_3 | PROVED | sql_equiv | 0.0 | 4.8 | yes | Bench/CrossSkill/Proven/sf_bq284_eq_0_3.lean |
| CrossSkill | sf_bq284_eq_1_2 | INCONCLUSIVE |  | 0.0 | 17.2 |  |  |
| CrossSkill | sf_bq284_eq_1_3 | INCONCLUSIVE |  | 0.0 | 20.3 |  |  |
| CrossSkill | sf_bq284_eq_2_3 | INCONCLUSIVE |  | 0.0 | 20.7 |  |  |
| CrossSkill | sf_bq285_eq_0_1 | INCONCLUSIVE |  | 0.0 | 79.2 |  |  |
| CrossSkill | sf_bq286_eq_0_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.3284 | 52.6 |  |  |
| CrossSkill | sf_bq286_eq_1_2 | PROVED | sql_equiv | 0.0 | 113.8 | yes | Bench/CrossSkill/Proven/sf_bq286_eq_1_2.lean |
| CrossSkill | sf_bq287_eq_0_1 | INCONCLUSIVE | exhausted | 0.6531 | 22.8 |  |  |
| CrossSkill | sf_bq287_eq_0_2 | INCONCLUSIVE | exhausted | 0.6849 | 29.1 |  |  |
| CrossSkill | sf_bq287_eq_0_3 | INCONCLUSIVE | exhausted | 0.6863 | 29.4 |  |  |
| CrossSkill | sf_bq287_eq_1_2 | INCONCLUSIVE | exhausted | 0.6541 | 24.6 |  |  |
| CrossSkill | sf_bq287_eq_1_3 | INCONCLUSIVE | exhausted | 0.6789 | 25.0 |  |  |
| CrossSkill | sf_bq287_eq_2_3 | INCONCLUSIVE | exhausted | 0.7855 | 37.3 |  |  |
| CrossSkill | sf_bq288_eq_1_2 | INCONCLUSIVE | exhausted | 2.1603 | 141.6 |  |  |
| CrossSkill | sf_bq290_eq_0_1 | INCONCLUSIVE |  | 0.0 | 106.1 |  |  |
| CrossSkill | sf_bq290_eq_0_2 | INCONCLUSIVE |  | 0.0 | 83.4 |  |  |
| CrossSkill | sf_bq290_eq_1_2 | INCONCLUSIVE |  | 0.0 | 75.2 |  |  |
| CrossSkill | sf_bq292_eq_0_1 | ELAB_ERROR |  | 0.0 | 5.3 |  |  |
| CrossSkill | sf_bq292_eq_0_2 | ELAB_ERROR |  | 0.0 | 5.4 |  |  |
| CrossSkill | sf_bq292_eq_0_3 | ELAB_ERROR |  | 0.0 | 5.3 |  |  |
| CrossSkill | sf_bq292_eq_1_2 | ELAB_ERROR |  | 0.0 | 5.2 |  |  |
| CrossSkill | sf_bq292_eq_1_3 | ELAB_ERROR |  | 0.0 | 5.2 |  |  |
| CrossSkill | sf_bq292_eq_2_3 | ELAB_ERROR |  | 0.0 | 5.7 |  |  |
| CrossSkill | sf_bq300_eq_0_1 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/CrossSkill/Proven/sf_bq300_eq_0_1.lean |
| CrossSkill | sf_bq300_eq_0_2 | INCONCLUSIVE |  | 0.0 | 21.5 |  |  |
| CrossSkill | sf_bq300_eq_1_2 | INCONCLUSIVE |  | 0.0 | 27.9 |  |  |
| CrossSkill | sf_bq301_eq_0_1 | INCONCLUSIVE |  | 0.0 | 96.8 |  |  |
| CrossSkill | sf_bq301_eq_0_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2336 | 36.6 |  |  |
| CrossSkill | sf_bq301_eq_0_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.5222 | 36.9 |  |  |
| CrossSkill | sf_bq301_eq_1_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.229 | 27.1 |  |  |
| CrossSkill | sf_bq301_eq_1_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2284 | 34.1 |  |  |
| CrossSkill | sf_bq301_eq_2_3 | INCONCLUSIVE |  | 0.0 | 256.6 |  |  |
| CrossSkill | sf_bq302_eq_0_1 | PROVED | sql_equiv | 0.0 | 7.5 | yes | Bench/CrossSkill/Proven/sf_bq302_eq_0_1.lean |
| CrossSkill | sf_bq302_eq_0_2 | INCONCLUSIVE |  | 0.0 | 36.1 |  |  |
| CrossSkill | sf_bq302_eq_0_3 | ELAB_ERROR |  | 0.0 | 31.8 |  |  |
| CrossSkill | sf_bq302_eq_1_2 | INCONCLUSIVE |  | 0.0 | 33.3 |  |  |
| CrossSkill | sf_bq302_eq_1_3 | ELAB_ERROR |  | 0.0 | 47.0 |  |  |
| CrossSkill | sf_bq302_eq_2_3 | INCONCLUSIVE | exhausted | 3.5159 | 245.4 |  |  |
| CrossSkill | sf_bq303_eq_0_1 | PROVED | sql_equiv | 0.0 | 6.2 | yes | Bench/CrossSkill/Proven/sf_bq303_eq_0_1.lean |
| CrossSkill | sf_bq303_eq_0_2 | INCONCLUSIVE |  | 0.0 | 75.7 |  |  |
| CrossSkill | sf_bq303_eq_1_2 | INCONCLUSIVE |  | 0.0 | 81.9 |  |  |
| CrossSkill | sf_bq304_eq_0_1 | INCONCLUSIVE |  | 0.0 | 44.3 |  |  |
| CrossSkill | sf_bq304_eq_0_2 | ELAB_ERROR |  | 0.0 | 88.5 |  |  |
| CrossSkill | sf_bq304_eq_0_3 | INCONCLUSIVE |  | 0.0 | 115.5 |  |  |
| CrossSkill | sf_bq304_eq_1_2 | ELAB_ERROR |  | 0.0 | 63.4 |  |  |
| CrossSkill | sf_bq304_eq_1_3 | INCONCLUSIVE |  | 0.0 | 54.6 |  |  |
| CrossSkill | sf_bq304_eq_2_3 | ELAB_ERROR |  | 0.0 | 113.1 |  |  |
| CrossSkill | sf_bq305_eq_0_1 | INCONCLUSIVE |  | 0.0 | 151.3 |  |  |
| CrossSkill | sf_bq305_eq_0_2 | INCONCLUSIVE |  | 0.0 | 220.0 |  |  |
| CrossSkill | sf_bq305_eq_0_3 | INCONCLUSIVE |  | 0.0 | 106.9 |  |  |
| CrossSkill | sf_bq305_eq_1_2 | INCONCLUSIVE |  | 0.0 | 145.1 |  |  |
| CrossSkill | sf_bq305_eq_1_3 | INCONCLUSIVE |  | 0.0 | 120.3 |  |  |
| CrossSkill | sf_bq305_eq_2_3 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq307_eq_0_1 | PROVED | llm | 0.7764 | 61.0 | yes | Bench/CrossSkill/Proven/sf_bq307_eq_0_1.lean |
| CrossSkill | sf_bq307_eq_0_2 | INCONCLUSIVE |  | 0.0 | 78.2 |  |  |
| CrossSkill | sf_bq307_eq_1_2 | INCONCLUSIVE |  | 0.0 | 63.1 |  |  |
| CrossSkill | sf_bq308_eq_0_1 | ELAB_ERROR |  | 0.0 | 9.7 |  |  |
| CrossSkill | sf_bq308_eq_0_2 | ELAB_ERROR |  | 0.0 | 95.9 |  |  |
| CrossSkill | sf_bq308_eq_1_2 | ELAB_ERROR |  | 0.0 | 141.2 |  |  |
| CrossSkill | sf_bq309_eq_0_1 | ELAB_ERROR |  | 0.0 | 167.2 |  |  |
| CrossSkill | sf_bq309_eq_0_2 | ELAB_ERROR |  | 0.0 | 96.1 |  |  |
| CrossSkill | sf_bq309_eq_0_3 | ELAB_ERROR |  | 0.0 | 103.0 |  |  |
| CrossSkill | sf_bq309_eq_1_2 | ELAB_ERROR |  | 0.0 | 79.1 |  |  |
| CrossSkill | sf_bq309_eq_1_3 | INCONCLUSIVE |  | 0.0 | 93.1 |  |  |
| CrossSkill | sf_bq309_eq_2_3 | ELAB_ERROR |  | 0.0 | 90.9 |  |  |
| CrossSkill | sf_bq310_eq_0_1 | INCONCLUSIVE |  | 0.0 | 22.3 |  |  |
| CrossSkill | sf_bq310_eq_0_2 | INCONCLUSIVE |  | 0.0 | 22.6 |  |  |
| CrossSkill | sf_bq310_eq_0_3 | INCONCLUSIVE |  | 0.0 | 33.1 |  |  |
| CrossSkill | sf_bq310_eq_1_2 | INCONCLUSIVE |  | 0.0 | 39.3 |  |  |
| CrossSkill | sf_bq310_eq_1_3 | INCONCLUSIVE |  | 0.0 | 24.1 |  |  |
| CrossSkill | sf_bq310_eq_2_3 | INCONCLUSIVE |  | 0.0 | 22.5 |  |  |
| CrossSkill | sf_bq323_eq_0_1 | ELAB_ERROR |  | 0.0 | 72.8 |  |  |
| CrossSkill | sf_bq323_eq_0_3 | ELAB_ERROR |  | 0.0 | 74.7 |  |  |
| CrossSkill | sf_bq323_eq_1_2 | ELAB_ERROR |  | 0.0 | 73.9 |  |  |
| CrossSkill | sf_bq323_eq_1_3 | ELAB_ERROR |  | 0.0 | 72.8 |  |  |
| CrossSkill | sf_bq324_eq_0_3 | ELAB_ERROR |  | 0.0 | 73.7 |  |  |
| CrossSkill | sf_bq325_eq_0_1 | INCONCLUSIVE |  | 0.0 | 80.3 |  |  |
| CrossSkill | sf_bq325_eq_0_2 | ELAB_ERROR |  | 0.0 | 93.3 |  |  |
| CrossSkill | sf_bq325_eq_0_3 | ELAB_ERROR |  | 0.0 | 79.9 |  |  |
| CrossSkill | sf_bq325_eq_1_2 | ELAB_ERROR |  | 0.0 | 80.7 |  |  |
| CrossSkill | sf_bq325_eq_1_3 | ELAB_ERROR |  | 0.0 | 89.5 |  |  |
| CrossSkill | sf_bq325_eq_2_3 | INCONCLUSIVE | exhausted | 0.6826 | 17.7 |  |  |
| CrossSkill | sf_bq326_eq_0_1 | ELAB_ERROR |  | 0.0 | 82.0 |  |  |
| CrossSkill | sf_bq326_eq_0_2 | ELAB_ERROR |  | 0.0 | 85.1 |  |  |
| CrossSkill | sf_bq326_eq_1_2 | ELAB_ERROR |  | 0.0 | 100.3 |  |  |
| CrossSkill | sf_bq328_eq_0_1 | INCONCLUSIVE |  | 0.0 | 31.6 |  |  |
| CrossSkill | sf_bq328_eq_0_2 | PROVED | sql_equiv | 0.0 | 15.6 | yes | Bench/CrossSkill/Proven/sf_bq328_eq_0_2.lean |
| CrossSkill | sf_bq328_eq_1_2 | INCONCLUSIVE |  | 0.0 | 40.2 |  |  |
| CrossSkill | sf_bq330_eq_0_1 | ELAB_ERROR |  | 0.0 | 71.8 |  |  |
| CrossSkill | sf_bq330_eq_0_2 | INCONCLUSIVE |  | 0.0 | 55.3 |  |  |
| CrossSkill | sf_bq330_eq_0_3 | INCONCLUSIVE |  | 0.0 | 47.1 |  |  |
| CrossSkill | sf_bq330_eq_1_2 | ELAB_ERROR |  | 0.0 | 108.5 |  |  |
| CrossSkill | sf_bq330_eq_1_3 | ELAB_ERROR |  | 0.0 | 91.0 |  |  |
| CrossSkill | sf_bq330_eq_2_3 | INCONCLUSIVE |  | 0.0 | 55.8 |  |  |
| CrossSkill | sf_bq331_eq_0_1 | ELAB_ERROR |  | 0.0 | 233.6 |  |  |
| CrossSkill | sf_bq331_eq_0_2 | INCONCLUSIVE |  | 0.0 | 254.0 |  |  |
| CrossSkill | sf_bq331_eq_0_3 | INCONCLUSIVE |  | 0.0 | 195.1 |  |  |
| CrossSkill | sf_bq331_eq_1_2 | INCONCLUSIVE |  | 0.0 | 183.8 |  |  |
| CrossSkill | sf_bq331_eq_1_3 | INCONCLUSIVE |  | 0.0 | 214.6 |  |  |
| CrossSkill | sf_bq331_eq_2_3 | INCONCLUSIVE |  | 0.0 | 178.4 |  |  |
| CrossSkill | sf_bq333_eq_0_1 | INCONCLUSIVE |  | 0.0 | 37.8 |  |  |
| CrossSkill | sf_bq333_eq_0_2 | INCONCLUSIVE |  | 0.0 | 34.0 |  |  |
| CrossSkill | sf_bq333_eq_0_3 | INCONCLUSIVE |  | 0.0 | 36.9 |  |  |
| CrossSkill | sf_bq333_eq_1_2 | INCONCLUSIVE | exhausted | 5.3872 | 404.0 |  |  |
| CrossSkill | sf_bq333_eq_1_3 | INCONCLUSIVE |  | 0.0 | 133.7 |  |  |
| CrossSkill | sf_bq333_eq_2_3 | INCONCLUSIVE | exhausted | 4.8791 | 351.1 |  |  |
| CrossSkill | sf_bq335_eq_0_1 | ELAB_ERROR |  | 0.0 | 61.6 |  |  |
| CrossSkill | sf_bq335_eq_0_2 | INCONCLUSIVE |  | 0.0 | 366.8 |  |  |
| CrossSkill | sf_bq335_eq_0_3 | ELAB_ERROR |  | 0.0 | 92.3 |  |  |
| CrossSkill | sf_bq335_eq_1_2 | ELAB_ERROR |  | 0.0 | 84.1 |  |  |
| CrossSkill | sf_bq335_eq_1_3 | INCONCLUSIVE | exhausted | 0.6583 | 16.3 |  |  |
| CrossSkill | sf_bq335_eq_2_3 | ELAB_ERROR |  | 0.0 | 127.9 |  |  |
| CrossSkill | sf_bq338_eq_0_1 | ELAB_ERROR |  | 0.0 | 68.8 |  |  |
| CrossSkill | sf_bq338_eq_0_2 | ELAB_ERROR |  | 0.0 | 72.5 |  |  |
| CrossSkill | sf_bq338_eq_0_3 | ELAB_ERROR |  | 0.0 | 67.8 |  |  |
| CrossSkill | sf_bq338_eq_1_2 | ELAB_ERROR |  | 0.0 | 73.8 |  |  |
| CrossSkill | sf_bq338_eq_1_3 | ELAB_ERROR |  | 0.0 | 72.7 |  |  |
| CrossSkill | sf_bq338_eq_2_3 | ELAB_ERROR |  | 0.0 | 73.9 |  |  |
| CrossSkill | sf_bq339_eq_0_1 | INCONCLUSIVE | exhausted | 3.1204 | 245.0 |  |  |
| CrossSkill | sf_bq339_eq_0_3 | ELAB_ERROR |  | 0.0 | 60.7 |  |  |
| CrossSkill | sf_bq339_eq_1_3 | ELAB_ERROR |  | 0.0 | 66.5 |  |  |
| CrossSkill | sf_bq340_eq_0_2 | INCONCLUSIVE |  | 0.0 | 53.7 |  |  |
| CrossSkill | sf_bq340_eq_0_3 | INCONCLUSIVE |  | 0.0 | 57.4 |  |  |
| CrossSkill | sf_bq340_eq_2_3 | INCONCLUSIVE |  | 0.0 | 94.9 |  |  |
| CrossSkill | sf_bq342_eq_0_1 | ELAB_ERROR |  | 0.0 | 493.3 |  |  |
| CrossSkill | sf_bq348_eq_0_1 | INCONCLUSIVE |  | 0.0 | 46.7 |  |  |
| CrossSkill | sf_bq350_eq_0_1 | INCONCLUSIVE |  | 0.0 | 26.4 |  |  |
| CrossSkill | sf_bq350_eq_0_2 | PROVED | sql_equiv | 0.0 | 6.1 | yes | Bench/CrossSkill/Proven/sf_bq350_eq_0_2.lean |
| CrossSkill | sf_bq350_eq_0_3 | PROVED | sql_equiv | 0.0 | 6.2 | yes | Bench/CrossSkill/Proven/sf_bq350_eq_0_3.lean |
| CrossSkill | sf_bq350_eq_1_2 | INCONCLUSIVE |  | 0.0 | 31.3 |  |  |
| CrossSkill | sf_bq350_eq_1_3 | INCONCLUSIVE |  | 0.0 | 30.2 |  |  |
| CrossSkill | sf_bq350_eq_2_3 | PROVED | sql_equiv | 0.0 | 4.8 | yes | Bench/CrossSkill/Proven/sf_bq350_eq_2_3.lean |
| CrossSkill | sf_bq352_eq_0_1 | ELAB_ERROR |  | 0.0 | 102.2 |  |  |
| CrossSkill | sf_bq352_eq_0_2 | ELAB_ERROR |  | 0.0 | 167.8 |  |  |
| CrossSkill | sf_bq352_eq_0_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2415 | 41.7 |  |  |
| CrossSkill | sf_bq352_eq_1_2 | ELAB_ERROR |  | 0.0 | 86.7 |  |  |
| CrossSkill | sf_bq352_eq_1_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2267 | 40.1 |  |  |
| CrossSkill | sf_bq352_eq_2_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.6218 | 57.2 |  |  |
| CrossSkill | sf_bq354_eq_0_1 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_bq355_eq_0_1 | ELAB_ERROR |  | 0.0 | 112.7 |  |  |
| CrossSkill | sf_bq355_eq_0_2 | INCONCLUSIVE |  | 0.0 | 89.8 |  |  |
| CrossSkill | sf_bq355_eq_0_3 | INCONCLUSIVE |  | 0.0 | 62.2 |  |  |
| CrossSkill | sf_bq355_eq_1_2 | INCONCLUSIVE |  | 0.0 | 55.1 |  |  |
| CrossSkill | sf_bq355_eq_1_3 | INCONCLUSIVE |  | 0.0 | 69.0 |  |  |
| CrossSkill | sf_bq355_eq_2_3 | INCONCLUSIVE |  | 0.0 | 77.0 |  |  |
| CrossSkill | sf_bq356_eq_0_1 | INCONCLUSIVE |  | 0.0 | 136.0 |  |  |
| CrossSkill | sf_bq356_eq_0_2 | ELAB_ERROR |  | 0.0 | 81.3 |  |  |
| CrossSkill | sf_bq356_eq_0_3 | INCONCLUSIVE |  | 0.0 | 113.5 |  |  |
| CrossSkill | sf_bq356_eq_1_2 | INCONCLUSIVE |  | 0.0 | 137.9 |  |  |
| CrossSkill | sf_bq356_eq_1_3 | INCONCLUSIVE | exhausted | 5.7732 | 480.6 |  |  |
| CrossSkill | sf_bq356_eq_2_3 | INCONCLUSIVE |  | 0.0 | 127.1 |  |  |
| CrossSkill | sf_bq357_eq_0_1 | ELAB_ERROR |  | 0.0 | 173.8 |  |  |
| CrossSkill | sf_bq357_eq_0_2 | INCONCLUSIVE |  | 0.0 | 66.3 |  |  |
| CrossSkill | sf_bq357_eq_1_2 | INCONCLUSIVE |  | 0.0 | 89.6 |  |  |
| CrossSkill | sf_bq360_eq_1_3 | ELAB_ERROR |  | 0.0 | 72.5 |  |  |
| CrossSkill | sf_bq361_eq_0_2 | INCONCLUSIVE | exhausted | 0.6514 | 17.0 |  |  |
| CrossSkill | sf_bq361_eq_0_3 | INCONCLUSIVE | exhausted | 0.695 | 19.4 |  |  |
| CrossSkill | sf_bq361_eq_2_3 | INCONCLUSIVE | exhausted | 0.659 | 17.3 |  |  |
| CrossSkill | sf_bq362_eq_0_1 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.3684 | 235.2 |  |  |
| CrossSkill | sf_bq363_eq_0_1 | INCONCLUSIVE |  | 0.0 | 150.7 |  |  |
| CrossSkill | sf_bq363_eq_0_2 | INCONCLUSIVE |  | 0.0 | 43.7 |  |  |
| CrossSkill | sf_bq363_eq_1_2 | INCONCLUSIVE |  | 0.0 | 40.2 |  |  |
| CrossSkill | sf_bq370_eq_0_1 | INCONCLUSIVE | exhausted | 0.6539 | 15.2 |  |  |
| CrossSkill | sf_bq370_eq_0_2 | ELAB_ERROR |  | 0.0 | 184.8 |  |  |
| CrossSkill | sf_bq370_eq_1_2 | ELAB_ERROR |  | 0.0 | 188.8 |  |  |
| CrossSkill | sf_bq371_eq_0_1 | INCONCLUSIVE | exhausted | 0.8823 | 36.4 |  |  |
| CrossSkill | sf_bq371_eq_0_2 | ELAB_ERROR |  | 0.0 | 78.1 |  |  |
| CrossSkill | sf_bq371_eq_1_2 | ELAB_ERROR |  | 0.0 | 105.5 |  |  |
| CrossSkill | sf_bq372_eq_0_1 | ELAB_ERROR |  | 0.0 | 62.0 |  |  |
| CrossSkill | sf_bq372_eq_0_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.6086 | 82.6 |  |  |
| CrossSkill | sf_bq372_eq_0_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2198 | 41.1 |  |  |
| CrossSkill | sf_bq372_eq_1_2 | ELAB_ERROR |  | 0.0 | 120.1 |  |  |
| CrossSkill | sf_bq372_eq_1_3 | ELAB_ERROR |  | 0.0 | 85.3 |  |  |
| CrossSkill | sf_bq372_eq_2_3 | ELAB_ERROR |  | 0.0 | 81.9 |  |  |
| CrossSkill | sf_bq373_eq_0_1 | INCONCLUSIVE | exhausted | 4.5199 | 335.7 |  |  |
| CrossSkill | sf_bq373_eq_0_2 | INCONCLUSIVE |  | 0.0 | 139.3 |  |  |
| CrossSkill | sf_bq373_eq_0_3 | INCONCLUSIVE |  | 0.0 | 159.4 |  |  |
| CrossSkill | sf_bq373_eq_1_2 | INCONCLUSIVE |  | 0.0 | 132.6 |  |  |
| CrossSkill | sf_bq373_eq_1_3 | INCONCLUSIVE |  | 0.0 | 129.3 |  |  |
| CrossSkill | sf_bq373_eq_2_3 | ELAB_ERROR |  | 0.0 | 534.1 |  |  |
| CrossSkill | sf_bq374_eq_0_1 | ELAB_ERROR |  | 0.0 | 130.4 |  |  |
| CrossSkill | sf_bq375_eq_0_2 | PROVED | sql_equiv | 0.0 | 8.7 | yes | Bench/CrossSkill/Proven/sf_bq375_eq_0_2.lean |
| CrossSkill | sf_bq379_eq_0_1 | INCONCLUSIVE |  | 0.0 | 222.3 |  |  |
| CrossSkill | sf_bq379_eq_0_2 | INCONCLUSIVE |  | 0.0 | 41.0 |  |  |
| CrossSkill | sf_bq379_eq_0_3 | INCONCLUSIVE |  | 0.0 | 39.0 |  |  |
| CrossSkill | sf_bq379_eq_1_2 | INCONCLUSIVE |  | 0.0 | 52.8 |  |  |
| CrossSkill | sf_bq379_eq_1_3 | INCONCLUSIVE |  | 0.0 | 55.4 |  |  |
| CrossSkill | sf_bq379_eq_2_3 | INCONCLUSIVE |  | 0.0 | 50.5 |  |  |
| CrossSkill | sf_bq380_eq_0_1 | ELAB_ERROR |  | 0.0 | 146.5 |  |  |
| CrossSkill | sf_bq380_eq_0_2 | INCONCLUSIVE |  | 0.0 | 61.5 |  |  |
| CrossSkill | sf_bq380_eq_0_3 | INCONCLUSIVE |  | 0.0 | 57.6 |  |  |
| CrossSkill | sf_bq380_eq_1_2 | INCONCLUSIVE |  | 0.0 | 48.8 |  |  |
| CrossSkill | sf_bq380_eq_1_3 | INCONCLUSIVE |  | 0.0 | 67.5 |  |  |
| CrossSkill | sf_bq380_eq_2_3 | INCONCLUSIVE |  | 0.0 | 62.7 |  |  |
| CrossSkill | sf_bq389_eq_0_1 | INCONCLUSIVE | exhausted | 0.7019 | 21.0 |  |  |
| CrossSkill | sf_bq389_eq_0_2 | ELAB_ERROR |  | 0.0 | 78.6 |  |  |
| CrossSkill | sf_bq389_eq_1_2 | ELAB_ERROR |  | 0.0 | 46.4 |  |  |
| CrossSkill | sf_bq391_eq_0_1 | INCONCLUSIVE | exhausted | 0.724 | 24.2 |  |  |
| CrossSkill | sf_bq391_eq_0_2 | INCONCLUSIVE | exhausted | 0.614 | 21.3 |  |  |
| CrossSkill | sf_bq391_eq_0_3 | INCONCLUSIVE | exhausted | 0.9248 | 43.9 |  |  |
| CrossSkill | sf_bq391_eq_1_2 | INCONCLUSIVE | exhausted | 0.658 | 23.8 |  |  |
| CrossSkill | sf_bq391_eq_1_3 | INCONCLUSIVE | exhausted | 0.7258 | 27.2 |  |  |
| CrossSkill | sf_bq391_eq_2_3 | INCONCLUSIVE | exhausted | 0.7326 | 33.2 |  |  |
| CrossSkill | sf_bq394_eq_0_1 | PROVED | sql_equiv | 0.0 | 11.2 | yes | Bench/CrossSkill/Proven/sf_bq394_eq_0_1.lean |
| CrossSkill | sf_bq394_eq_0_2 | INCONCLUSIVE |  | 0.0 | 80.6 |  |  |
| CrossSkill | sf_bq394_eq_0_3 | INCONCLUSIVE | exhausted | 2.7494 | 112.9 |  |  |
| CrossSkill | sf_bq394_eq_1_2 | INCONCLUSIVE |  | 0.0 | 67.9 |  |  |
| CrossSkill | sf_bq394_eq_1_3 | INCONCLUSIVE | exhausted | 3.4869 | 173.3 |  |  |
| CrossSkill | sf_bq394_eq_2_3 | INCONCLUSIVE | exhausted | 3.9576 | 193.6 |  |  |
| CrossSkill | sf_bq395_eq_0_1 | INCONCLUSIVE |  | 0.0 | 153.1 |  |  |
| CrossSkill | sf_bq395_eq_0_2 | ELAB_ERROR |  | 0.0 | 139.7 |  |  |
| CrossSkill | sf_bq395_eq_1_2 | INCONCLUSIVE |  | 0.0 | 174.7 |  |  |
| CrossSkill | sf_bq395_eq_1_3 | INCONCLUSIVE |  | 0.0 | 92.7 |  |  |
| CrossSkill | sf_bq396_eq_0_2 | INCONCLUSIVE |  | 0.0 | 78.3 |  |  |
| CrossSkill | sf_bq396_eq_0_3 | INCONCLUSIVE | exhausted | 5.4938 | 399.2 |  |  |
| CrossSkill | sf_bq396_eq_2_3 | INCONCLUSIVE | exhausted | 4.2933 | 311.3 |  |  |
| CrossSkill | sf_bq397_eq_0_1 | ELAB_ERROR |  | 0.0 | 265.6 |  |  |
| CrossSkill | sf_bq397_eq_0_2 | ELAB_ERROR |  | 0.0 | 426.4 |  |  |
| CrossSkill | sf_bq397_eq_0_3 | INCONCLUSIVE | exhausted | 5.2222 | 374.4 |  |  |
| CrossSkill | sf_bq397_eq_1_2 | INCONCLUSIVE |  | 0.0 | 64.6 |  |  |
| CrossSkill | sf_bq397_eq_1_3 | INCONCLUSIVE |  | 0.0 | 103.7 |  |  |
| CrossSkill | sf_bq397_eq_2_3 | INCONCLUSIVE |  | 0.0 | 67.4 |  |  |
| CrossSkill | sf_bq398_eq_0_1 | INCONCLUSIVE |  | 0.0 | 31.7 |  |  |
| CrossSkill | sf_bq399_eq_0_1 | INCONCLUSIVE |  | 0.0 | 38.2 |  |  |
| CrossSkill | sf_bq400_eq_0_1 | ELAB_ERROR |  | 0.0 | 124.6 |  |  |
| CrossSkill | sf_bq400_eq_0_2 | ELAB_ERROR |  | 0.0 | 164.0 |  |  |
| CrossSkill | sf_bq400_eq_0_3 | ELAB_ERROR |  | 0.0 | 105.6 |  |  |
| CrossSkill | sf_bq400_eq_1_2 | ELAB_ERROR |  | 0.0 | 69.7 |  |  |
| CrossSkill | sf_bq400_eq_1_3 | ELAB_ERROR |  | 0.0 | 108.3 |  |  |
| CrossSkill | sf_bq400_eq_2_3 | ELAB_ERROR |  | 0.0 | 70.2 |  |  |
| CrossSkill | sf_bq402_eq_0_1 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2225 | 23.3 |  |  |
| CrossSkill | sf_bq402_eq_0_2 | INCONCLUSIVE |  | 0.0 | 33.8 |  |  |
| CrossSkill | sf_bq402_eq_0_3 | PROVED | sql_equiv | 0.0 | 7.6 | yes | Bench/CrossSkill/Proven/sf_bq402_eq_0_3.lean |
| CrossSkill | sf_bq402_eq_1_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2467 | 29.6 |  |  |
| CrossSkill | sf_bq402_eq_1_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.1967 | 22.8 |  |  |
| CrossSkill | sf_bq402_eq_2_3 | INCONCLUSIVE |  | 0.0 | 31.6 |  |  |
| CrossSkill | sf_bq403_eq_0_1 | ELAB_ERROR |  | 0.0 | 71.9 |  |  |
| CrossSkill | sf_bq403_eq_0_2 | ELAB_ERROR |  | 0.0 | 68.7 |  |  |
| CrossSkill | sf_bq403_eq_0_3 | ELAB_ERROR |  | 0.0 | 69.8 |  |  |
| CrossSkill | sf_bq403_eq_1_2 | ELAB_ERROR |  | 0.0 | 130.4 |  |  |
| CrossSkill | sf_bq403_eq_1_3 | ELAB_ERROR |  | 0.0 | 146.5 |  |  |
| CrossSkill | sf_bq403_eq_2_3 | INCONCLUSIVE | exhausted | 0.6678 | 21.6 |  |  |
| CrossSkill | sf_bq407_eq_0_1 | ELAB_ERROR |  | 0.0 | 74.4 |  |  |
| CrossSkill | sf_bq407_eq_0_2 | ELAB_ERROR |  | 0.0 | 75.5 |  |  |
| CrossSkill | sf_bq407_eq_0_3 | ELAB_ERROR |  | 0.0 | 164.4 |  |  |
| CrossSkill | sf_bq407_eq_1_2 | ELAB_ERROR |  | 0.0 | 75.2 |  |  |
| CrossSkill | sf_bq407_eq_1_3 | ELAB_ERROR |  | 0.0 | 164.5 |  |  |
| CrossSkill | sf_bq407_eq_2_3 | ELAB_ERROR |  | 0.0 | 119.4 |  |  |
| CrossSkill | sf_bq410_eq_0_1 | ELAB_ERROR |  | 0.0 | 72.6 |  |  |
| CrossSkill | sf_bq410_eq_0_2 | ELAB_ERROR |  | 0.0 | 73.1 |  |  |
| CrossSkill | sf_bq410_eq_0_3 | ELAB_ERROR |  | 0.0 | 73.0 |  |  |
| CrossSkill | sf_bq410_eq_1_2 | ELAB_ERROR |  | 0.0 | 75.1 |  |  |
| CrossSkill | sf_bq410_eq_1_3 | ELAB_ERROR |  | 0.0 | 75.0 |  |  |
| CrossSkill | sf_bq410_eq_2_3 | ELAB_ERROR |  | 0.0 | 77.3 |  |  |
| CrossSkill | sf_bq411_eq_0_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2683 | 25.6 |  |  |
| CrossSkill | sf_bq413_eq_0_1 | PROVED | sql_equiv | 0.0 | 7.0 | yes | Bench/CrossSkill/Proven/sf_bq413_eq_0_1.lean |
| CrossSkill | sf_bq413_eq_0_2 | INCONCLUSIVE |  | 0.0 | 131.4 |  |  |
| CrossSkill | sf_bq413_eq_0_3 | ELAB_ERROR |  | 0.0 | 78.2 |  |  |
| CrossSkill | sf_bq413_eq_1_2 | INCONCLUSIVE |  | 0.0 | 136.0 |  |  |
| CrossSkill | sf_bq413_eq_1_3 | ELAB_ERROR |  | 0.0 | 78.5 |  |  |
| CrossSkill | sf_bq413_eq_2_3 | ELAB_ERROR |  | 0.0 | 98.1 |  |  |
| CrossSkill | sf_bq414_eq_0_1 | INCONCLUSIVE |  | 0.0 | 305.8 |  |  |
| CrossSkill | sf_bq414_eq_0_2 | INCONCLUSIVE |  | 0.0 | 75.3 |  |  |
| CrossSkill | sf_bq414_eq_0_3 | INCONCLUSIVE |  | 0.0 | 104.5 |  |  |
| CrossSkill | sf_bq414_eq_1_2 | INCONCLUSIVE |  | 0.0 | 74.4 |  |  |
| CrossSkill | sf_bq414_eq_1_3 | INCONCLUSIVE |  | 0.0 | 57.6 |  |  |
| CrossSkill | sf_bq414_eq_2_3 | PROVED | sql_equiv | 0.0 | 12.6 | yes | Bench/CrossSkill/Proven/sf_bq414_eq_2_3.lean |
| CrossSkill | sf_bq415_eq_0_1 | ELAB_ERROR |  | 0.0 | 49.0 |  |  |
| CrossSkill | sf_bq418_eq_0_1 | ELAB_ERROR |  | 0.0 | 187.0 |  |  |
| CrossSkill | sf_bq418_eq_0_2 | ELAB_ERROR |  | 0.0 | 213.6 |  |  |
| CrossSkill | sf_bq418_eq_1_2 | ELAB_ERROR |  | 0.0 | 120.0 |  |  |
| CrossSkill | sf_bq419_eq_0_1 | INCONCLUSIVE | exhausted | 4.637 | 302.9 |  |  |
| CrossSkill | sf_bq419_eq_0_2 | INCONCLUSIVE |  | 0.0 | 266.2 |  |  |
| CrossSkill | sf_bq419_eq_0_3 | INCONCLUSIVE |  | 0.0 | 199.8 |  |  |
| CrossSkill | sf_bq419_eq_1_2 | INCONCLUSIVE |  | 0.0 | 187.9 |  |  |
| CrossSkill | sf_bq419_eq_1_3 | INCONCLUSIVE |  | 0.0 | 105.2 |  |  |
| CrossSkill | sf_bq419_eq_2_3 | INCONCLUSIVE | exhausted | 5.4236 | 338.3 |  |  |
| CrossSkill | sf_bq420_eq_0_1 | ELAB_ERROR |  | 0.0 | 73.5 |  |  |
| CrossSkill | sf_bq423_eq_0_2 | PROVED | sql_equiv | 0.0 | 6.7 | yes | Bench/CrossSkill/Proven/sf_bq423_eq_0_2.lean |
| CrossSkill | sf_bq423_eq_0_3 | INCONCLUSIVE |  | 0.0 | 163.4 |  |  |
| CrossSkill | sf_bq423_eq_2_3 | INCONCLUSIVE |  | 0.0 | 127.9 |  |  |
| CrossSkill | sf_bq425_eq_0_1 | ELAB_ERROR |  | 0.0 | 181.0 |  |  |
| CrossSkill | sf_bq425_eq_0_2 | INCONCLUSIVE |  | 0.0 | 167.5 |  |  |
| CrossSkill | sf_bq425_eq_0_3 | ELAB_ERROR |  | 0.0 | 139.2 |  |  |
| CrossSkill | sf_bq425_eq_1_2 | INCONCLUSIVE |  | 0.0 | 224.7 |  |  |
| CrossSkill | sf_bq425_eq_1_3 | ELAB_ERROR |  | 0.0 | 283.5 |  |  |
| CrossSkill | sf_bq425_eq_2_3 | INCONCLUSIVE |  | 0.0 | 190.3 |  |  |
| CrossSkill | sf_bq426_eq_0_1 | ELAB_ERROR |  | 0.0 | 108.1 |  |  |
| CrossSkill | sf_bq426_eq_0_2 | INCONCLUSIVE | exhausted | 0.6731 | 19.7 |  |  |
| CrossSkill | sf_bq426_eq_0_3 | INCONCLUSIVE | exhausted | 0.6461 | 16.1 |  |  |
| CrossSkill | sf_bq426_eq_1_2 | INCONCLUSIVE | exhausted | 2.033 | 141.0 |  |  |
| CrossSkill | sf_bq426_eq_1_3 | INCONCLUSIVE | exhausted | 3.1633 | 250.3 |  |  |
| CrossSkill | sf_bq426_eq_2_3 | INCONCLUSIVE | exhausted | 0.8412 | 35.8 |  |  |
| CrossSkill | sf_bq428_eq_0_1 | ELAB_ERROR |  | 0.0 | 69.0 |  |  |
| CrossSkill | sf_bq428_eq_0_2 | ELAB_ERROR |  | 0.0 | 68.5 |  |  |
| CrossSkill | sf_bq428_eq_0_3 | ELAB_ERROR |  | 0.0 | 67.8 |  |  |
| CrossSkill | sf_bq428_eq_1_2 | INCONCLUSIVE | exhausted | 0.7716 | 55.6 |  |  |
| CrossSkill | sf_bq428_eq_1_3 | ELAB_ERROR |  | 0.0 | 67.6 |  |  |
| CrossSkill | sf_bq428_eq_2_3 | ELAB_ERROR |  | 0.0 | 67.8 |  |  |
| CrossSkill | sf_bq432_eq_2_3 | PROVED | sql_equiv | 0.0 | 5.1 | yes | Bench/CrossSkill/Proven/sf_bq432_eq_2_3.lean |
| CrossSkill | sf_bq441_eq_0_1 | ELAB_ERROR |  | 0.0 | 84.6 |  |  |
| CrossSkill | sf_bq442_eq_0_3 | ELAB_ERROR |  | 0.0 | 109.5 |  |  |
| CrossSkill | sf_bq442_eq_1_2 | INCONCLUSIVE | exhausted | 1.8053 | 115.1 |  |  |
| CrossSkill | sf_bq445_eq_0_1 | ELAB_ERROR |  | 0.0 | 81.6 |  |  |
| CrossSkill | sf_bq451_eq_0_1 | ELAB_ERROR |  | 0.0 | 156.0 |  |  |
| CrossSkill | sf_bq451_eq_0_3 | ELAB_ERROR |  | 0.0 | 85.5 |  |  |
| CrossSkill | sf_bq451_eq_1_3 | INCONCLUSIVE | exhausted | 3.5131 | 283.4 |  |  |
| CrossSkill | sf_bq452_eq_0_1 | ELAB_ERROR |  | 0.0 | 133.6 |  |  |
| CrossSkill | sf_bq452_eq_0_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2117 | 39.5 |  |  |
| CrossSkill | sf_bq452_eq_0_3 | ELAB_ERROR |  | 0.0 | 161.4 |  |  |
| CrossSkill | sf_bq452_eq_1_2 | ELAB_ERROR |  | 0.0 | 136.1 |  |  |
| CrossSkill | sf_bq452_eq_1_3 | ELAB_ERROR |  | 0.0 | 147.9 |  |  |
| CrossSkill | sf_bq452_eq_2_3 | ELAB_ERROR |  | 0.0 | 158.2 |  |  |
| CrossSkill | sf_bq453_eq_0_1 | ELAB_ERROR |  | 0.0 | 82.9 |  |  |
| CrossSkill | sf_bq454_eq_0_1 | INCONCLUSIVE |  | 0.0 | 90.6 |  |  |
| CrossSkill | sf_bq454_eq_0_2 | INCONCLUSIVE |  | 0.0 | 99.5 |  |  |
| CrossSkill | sf_bq454_eq_1_2 | INCONCLUSIVE |  | 0.0 | 112.5 |  |  |
| CrossSkill | sf_bq456_eq_0_1 | ELAB_ERROR |  | 0.0 | 72.1 |  |  |
| CrossSkill | sf_bq456_eq_0_2 | ELAB_ERROR |  | 0.0 | 73.0 |  |  |
| CrossSkill | sf_bq456_eq_0_3 | ELAB_ERROR |  | 0.0 | 73.4 |  |  |
| CrossSkill | sf_bq456_eq_1_2 | ELAB_ERROR |  | 0.0 | 73.7 |  |  |
| CrossSkill | sf_bq456_eq_1_3 | ELAB_ERROR |  | 0.0 | 73.3 |  |  |
| CrossSkill | sf_bq456_eq_2_3 | ELAB_ERROR |  | 0.0 | 73.4 |  |  |
| CrossSkill | sf_bq457_eq_0_1 | ELAB_ERROR |  | 0.0 | 195.2 |  |  |
| CrossSkill | sf_bq457_eq_0_2 | ELAB_ERROR |  | 0.0 | 92.4 |  |  |
| CrossSkill | sf_bq457_eq_0_3 | ELAB_ERROR |  | 0.0 | 177.2 |  |  |
| CrossSkill | sf_bq457_eq_1_2 | INCONCLUSIVE |  | 0.0 | 69.4 |  |  |
| CrossSkill | sf_bq457_eq_1_3 | INCONCLUSIVE |  | 0.0 | 75.2 |  |  |
| CrossSkill | sf_bq457_eq_2_3 | PROVED | sql_equiv | 0.0 | 6.3 | yes | Bench/CrossSkill/Proven/sf_bq457_eq_2_3.lean |
| CrossSkill | sf_bq460_eq_0_1 | INCONCLUSIVE | exhausted | 0.6732 | 18.6 |  |  |
| CrossSkill | sf_bq460_eq_0_2 | INCONCLUSIVE | exhausted | 0.9015 | 159.5 |  |  |
| CrossSkill | sf_bq460_eq_1_2 | INCONCLUSIVE | exhausted | 0.6688 | 98.5 |  |  |
| CrossSkill | sf_bq461_eq_0_1 | ELAB_ERROR |  | 0.0 | 61.5 |  |  |
| CrossSkill | sf_bq461_eq_0_2 | ELAB_ERROR |  | 0.0 | 98.2 |  |  |
| CrossSkill | sf_bq461_eq_1_2 | INCONCLUSIVE | unprovable-unverified | 0.2455 | 159.4 |  |  |
| CrossSkill | sf_bq462_eq_0_1 | ELAB_ERROR |  | 0.0 | 87.4 |  |  |
| CrossSkill | sf_bq462_eq_0_2 | ELAB_ERROR |  | 0.0 | 111.7 |  |  |
| CrossSkill | sf_bq462_eq_1_2 | ELAB_ERROR |  | 0.0 | 144.7 |  |  |
| CrossSkill | sf_ga003_eq_0_1 | ELAB_ERROR |  | 0.0 | 142.1 |  |  |
| CrossSkill | sf_ga003_eq_0_2 | ELAB_ERROR |  | 0.0 | 138.5 |  |  |
| CrossSkill | sf_ga003_eq_1_2 | INCONCLUSIVE |  | 0.0 | 150.9 |  |  |
| CrossSkill | sf_ga004_eq_0_1 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.5162 | 35.9 |  |  |
| CrossSkill | sf_ga004_eq_0_2 | ELAB_ERROR |  | 0.0 | 139.3 |  |  |
| CrossSkill | sf_ga004_eq_0_3 | INCONCLUSIVE | exhausted | 1.0378 | 53.7 |  |  |
| CrossSkill | sf_ga004_eq_1_2 | ELAB_ERROR |  | 0.0 | 107.7 |  |  |
| CrossSkill | sf_ga004_eq_1_3 | INCONCLUSIVE | exhausted | 0.7432 | 28.2 |  |  |
| CrossSkill | sf_ga004_eq_2_3 | INCONCLUSIVE | exhausted | 4.3618 | 211.4 |  |  |
| CrossSkill | sf_ga006_eq_0_1 | ELAB_ERROR |  | 0.0 | 182.0 |  |  |
| CrossSkill | sf_ga006_eq_0_2 | ELAB_ERROR |  | 0.0 | 202.6 |  |  |
| CrossSkill | sf_ga006_eq_0_3 | ELAB_ERROR |  | 0.0 | 196.8 |  |  |
| CrossSkill | sf_ga006_eq_1_2 | ELAB_ERROR |  | 0.0 | 84.4 |  |  |
| CrossSkill | sf_ga006_eq_1_3 | ELAB_ERROR |  | 0.0 | 206.0 |  |  |
| CrossSkill | sf_ga006_eq_2_3 | ELAB_ERROR |  | 0.0 | 158.8 |  |  |
| CrossSkill | sf_ga007_eq_0_2 | INCONCLUSIVE |  | 0.0 | 62.6 |  |  |
| CrossSkill | sf_ga008_eq_0_1 | ELAB_ERROR |  | 0.0 | 160.5 |  |  |
| CrossSkill | sf_ga008_eq_0_2 | PROVED | sql_equiv | 0.0 | 59.1 | yes | Bench/CrossSkill/Proven/sf_ga008_eq_0_2.lean |
| CrossSkill | sf_ga008_eq_0_3 | PROVED | sql_equiv | 0.0 | 13.2 | yes | Bench/CrossSkill/Proven/sf_ga008_eq_0_3.lean |
| CrossSkill | sf_ga008_eq_1_2 | ELAB_ERROR |  | 0.0 | 103.8 |  |  |
| CrossSkill | sf_ga008_eq_1_3 | ELAB_ERROR |  | 0.0 | 131.9 |  |  |
| CrossSkill | sf_ga008_eq_2_3 | PROVED | sql_equiv | 0.0 | 58.6 | yes | Bench/CrossSkill/Proven/sf_ga008_eq_2_3.lean |
| CrossSkill | sf_ga009_eq_0_1 | ELAB_ERROR |  | 0.0 | 117.8 |  |  |
| CrossSkill | sf_ga009_eq_0_2 | INCONCLUSIVE | exhausted | 0.6996 | 59.4 |  |  |
| CrossSkill | sf_ga009_eq_1_2 | ELAB_ERROR |  | 0.0 | 135.3 |  |  |
| CrossSkill | sf_ga010_eq_0_1 | INCONCLUSIVE | exhausted | 0.6944 | 27.0 |  |  |
| CrossSkill | sf_ga010_eq_0_2 | INCONCLUSIVE | exhausted | 0.7154 | 24.0 |  |  |
| CrossSkill | sf_ga010_eq_0_3 | INCONCLUSIVE | exhausted | 0.6938 | 27.5 |  |  |
| CrossSkill | sf_ga010_eq_1_2 | INCONCLUSIVE | exhausted | 0.6846 | 23.0 |  |  |
| CrossSkill | sf_ga010_eq_1_3 | INCONCLUSIVE | exhausted | 0.6674 | 27.0 |  |  |
| CrossSkill | sf_ga010_eq_2_3 | INCONCLUSIVE | exhausted | 0.8956 | 45.2 |  |  |
| CrossSkill | sf_ga011_eq_0_1 | INCONCLUSIVE |  | 0.0 | 91.0 |  |  |
| CrossSkill | sf_ga011_eq_0_2 | INCONCLUSIVE |  | 0.0 | 117.1 |  |  |
| CrossSkill | sf_ga011_eq_0_3 | INCONCLUSIVE |  | 0.0 | 58.1 |  |  |
| CrossSkill | sf_ga011_eq_1_2 | INCONCLUSIVE |  | 0.0 | 103.1 |  |  |
| CrossSkill | sf_ga011_eq_1_3 | INCONCLUSIVE |  | 0.0 | 56.7 |  |  |
| CrossSkill | sf_ga011_eq_2_3 | INCONCLUSIVE |  | 0.0 | 40.1 |  |  |
| CrossSkill | sf_ga012_eq_2_3 | ELAB_ERROR |  | 0.0 | 49.2 |  |  |
| CrossSkill | sf_ga013_eq_2_3 | INCONCLUSIVE | exhausted | 0.6666 | 28.3 |  |  |
| CrossSkill | sf_ga017_eq_0_1 | ELAB_ERROR |  | 0.0 | 83.6 |  |  |
| CrossSkill | sf_ga017_eq_0_2 | ELAB_ERROR |  | 0.0 | 86.7 |  |  |
| CrossSkill | sf_ga017_eq_0_3 | ELAB_ERROR |  | 0.0 | 85.6 |  |  |
| CrossSkill | sf_ga017_eq_1_2 | ELAB_ERROR |  | 0.0 | 80.2 |  |  |
| CrossSkill | sf_ga017_eq_1_3 | ELAB_ERROR |  | 0.0 | 79.7 |  |  |
| CrossSkill | sf_ga017_eq_2_3 | ELAB_ERROR |  | 0.0 | 86.0 |  |  |
| CrossSkill | sf_ga019_eq_0_1 | ELAB_ERROR |  | 0.0 | 142.0 |  |  |
| CrossSkill | sf_ga019_eq_0_2 | ELAB_ERROR |  | 0.0 | 136.9 |  |  |
| CrossSkill | sf_ga019_eq_1_2 | ELAB_ERROR |  | 0.0 | 146.8 |  |  |
| CrossSkill | sf_ga022_eq_0_1 | INCONCLUSIVE | exhausted | 0.7204 | 22.8 |  |  |
| CrossSkill | sf_ga025_eq_0_1 | ELAB_ERROR |  | 0.0 | 91.6 |  |  |
| CrossSkill | sf_ga025_eq_0_2 | ELAB_ERROR |  | 0.0 | 82.5 |  |  |
| CrossSkill | sf_ga025_eq_1_2 | ELAB_ERROR |  | 0.0 | 93.4 |  |  |
| CrossSkill | sf_ga028_eq_0_1 | ELAB_ERROR |  | 0.0 | 87.7 |  |  |
| CrossSkill | sf_ga028_eq_0_2 | ELAB_ERROR |  | 0.0 | 107.9 |  |  |
| CrossSkill | sf_ga028_eq_1_2 | ELAB_ERROR |  | 0.0 | 102.8 |  |  |
| CrossSkill | sf_ga030_eq_0_1 | ELAB_ERROR |  | 0.0 | 118.6 |  |  |
| CrossSkill | sf_ga030_eq_0_2 | ELAB_ERROR |  | 0.0 | 122.1 |  |  |
| CrossSkill | sf_ga030_eq_0_3 | ELAB_ERROR |  | 0.0 | 120.8 |  |  |
| CrossSkill | sf_ga030_eq_1_2 | ELAB_ERROR |  | 0.0 | 84.1 |  |  |
| CrossSkill | sf_ga030_eq_1_3 | ELAB_ERROR |  | 0.0 | 77.5 |  |  |
| CrossSkill | sf_ga030_eq_2_3 | ELAB_ERROR |  | 0.0 | 83.0 |  |  |
| CrossSkill | sf_ga031_eq_1_2 | INCONCLUSIVE | exhausted | 0.6518 | 22.5 |  |  |
| CrossSkill | sf_ga032_eq_1_2 | INCONCLUSIVE | exhausted | 1.7984 | 104.4 |  |  |
| CrossSkill | sf_local002_eq_0_1 | INCONCLUSIVE | exhausted | 0.6401 | 30.9 |  |  |
| CrossSkill | sf_local002_eq_0_2 | INCONCLUSIVE | exhausted | 0.6883 | 26.6 |  |  |
| CrossSkill | sf_local002_eq_1_2 | INCONCLUSIVE | exhausted | 0.851 | 41.0 |  |  |
| CrossSkill | sf_local007_eq_0_1 | PROVED | llm | 0.3813 | 23.8 | yes | Bench/CrossSkill/Proven/sf_local007_eq_0_1.lean |
| CrossSkill | sf_local007_eq_0_2 | INCONCLUSIVE |  | 0.0 | 34.4 |  |  |
| CrossSkill | sf_local007_eq_1_2 | INCONCLUSIVE |  | 0.0 | 21.9 |  |  |
| CrossSkill | sf_local008_eq_0_1 | INCONCLUSIVE | exhausted | 0.6645 | 20.2 |  |  |
| CrossSkill | sf_local008_eq_0_2 | INCONCLUSIVE | exhausted | 0.6621 | 22.5 |  |  |
| CrossSkill | sf_local008_eq_0_3 | INCONCLUSIVE | exhausted | 0.6709 | 23.9 |  |  |
| CrossSkill | sf_local008_eq_1_2 | INCONCLUSIVE | exhausted | 0.6675 | 21.3 |  |  |
| CrossSkill | sf_local008_eq_1_3 | INCONCLUSIVE | exhausted | 0.6547 | 19.1 |  |  |
| CrossSkill | sf_local008_eq_2_3 | INCONCLUSIVE | exhausted | 0.8734 | 36.1 |  |  |
| CrossSkill | sf_local017_eq_0_1 | ELAB_ERROR |  | 0.0 | 169.5 |  |  |
| CrossSkill | sf_local017_eq_0_3 | ELAB_ERROR |  | 0.0 | 229.5 |  |  |
| CrossSkill | sf_local017_eq_1_3 | ELAB_ERROR |  | 0.0 | 129.1 |  |  |
| CrossSkill | sf_local018_eq_0_2 | ELAB_ERROR |  | 0.0 | 79.2 |  |  |
| CrossSkill | sf_local018_eq_0_3 | ELAB_ERROR |  | 0.0 | 161.3 |  |  |
| CrossSkill | sf_local018_eq_2_3 | ELAB_ERROR |  | 0.0 | 79.5 |  |  |
| CrossSkill | sf_local020_eq_0_1 | DISPROVED(unverified-artifact) | plausible_sql | 0.4092 | 98.3 | NO |  |
| CrossSkill | sf_local020_eq_0_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.287 | 84.1 | NO |  |
| CrossSkill | sf_local020_eq_0_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.2624 | 86.1 | NO |  |
| CrossSkill | sf_local020_eq_1_2 | ELAB_ERROR |  | 0.0 | 86.0 |  |  |
| CrossSkill | sf_local020_eq_1_3 | ELAB_ERROR |  | 0.0 | 149.0 |  |  |
| CrossSkill | sf_local020_eq_2_3 | INCONCLUSIVE | exhausted | 0.6646 | 17.2 |  |  |
| CrossSkill | sf_local021_eq_0_1 | DISPROVED(unverified-artifact) | plausible_sql | 0.3611 | 77.4 | NO |  |
| CrossSkill | sf_local021_eq_0_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.3611 | 90.3 | NO |  |
| CrossSkill | sf_local021_eq_1_2 | INCONCLUSIVE | exhausted | 0.6512 | 18.4 |  |  |
| CrossSkill | sf_local023_eq_0_1 | ELAB_ERROR |  | 0.0 | 152.8 |  |  |
| CrossSkill | sf_local023_eq_0_2 | INCONCLUSIVE |  | 0.0 | 92.3 |  |  |
| CrossSkill | sf_local023_eq_0_3 | ELAB_ERROR |  | 0.0 | 143.8 |  |  |
| CrossSkill | sf_local023_eq_1_2 | ELAB_ERROR |  | 0.0 | 94.5 |  |  |
| CrossSkill | sf_local023_eq_1_3 | ELAB_ERROR |  | 0.0 | 214.0 |  |  |
| CrossSkill | sf_local023_eq_2_3 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local024_eq_0_1 | ELAB_ERROR |  | 0.0 | 218.0 |  |  |
| CrossSkill | sf_local024_eq_0_2 | ELAB_ERROR |  | 0.0 | 298.0 |  |  |
| CrossSkill | sf_local024_eq_1_2 | PROVED | sql_equiv | 0.0 | 14.1 | yes | Bench/CrossSkill/Proven/sf_local024_eq_1_2.lean |
| CrossSkill | sf_local025_eq_0_1 | INCONCLUSIVE | exhausted | 0.6731 | 22.3 |  |  |
| CrossSkill | sf_local029_eq_0_1 | DISPROVED(unverified-artifact) | plausible_sql | 0.4069 | 67.7 | NO |  |
| CrossSkill | sf_local029_eq_0_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.3153 | 86.6 | NO |  |
| CrossSkill | sf_local029_eq_1_2 | INCONCLUSIVE |  | 0.0 | 56.5 |  |  |
| CrossSkill | sf_local031_eq_1_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.4128 | 37.7 | NO |  |
| CrossSkill | sf_local032_eq_0_1 | INCONCLUSIVE |  | 0.0 | 140.6 |  |  |
| CrossSkill | sf_local032_eq_0_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.3376 | 58.0 | NO |  |
| CrossSkill | sf_local032_eq_1_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.3151 | 58.5 | NO |  |
| CrossSkill | sf_local034_eq_0_1 | INCONCLUSIVE |  | 0.0 | 38.4 |  |  |
| CrossSkill | sf_local034_eq_0_2 | PROVED | sql_equiv | 0.0 | 30.7 | yes | Bench/CrossSkill/Proven/sf_local034_eq_0_2.lean |
| CrossSkill | sf_local034_eq_0_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.3599 | 79.2 | NO |  |
| CrossSkill | sf_local034_eq_1_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.3772 | 48.0 | NO |  |
| CrossSkill | sf_local034_eq_1_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.3043 | 57.0 | NO |  |
| CrossSkill | sf_local034_eq_2_3 | INCONCLUSIVE |  | 0.0 | 89.7 |  |  |
| CrossSkill | sf_local035_eq_0_1 | DISPROVED(unverified-artifact) | plausible_sql | 0.2342 | 33.5 | NO |  |
| CrossSkill | sf_local035_eq_0_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2349 | 30.5 |  |  |
| CrossSkill | sf_local035_eq_0_3 | ELAB_ERROR |  | 0.0 | 40.2 |  |  |
| CrossSkill | sf_local035_eq_1_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.2895 | 36.1 | NO |  |
| CrossSkill | sf_local035_eq_1_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.2463 | 54.2 | NO |  |
| CrossSkill | sf_local035_eq_2_3 | PROVED | sql_equiv | 0.0 | 4.9 | yes | Bench/CrossSkill/Proven/sf_local035_eq_2_3.lean |
| CrossSkill | sf_local040_eq_0_1 | ELAB_ERROR |  | 0.0 | 274.6 |  |  |
| CrossSkill | sf_local040_eq_0_2 | ELAB_ERROR |  | 0.0 | 165.9 |  |  |
| CrossSkill | sf_local040_eq_0_3 | ELAB_ERROR |  | 0.0 | 78.0 |  |  |
| CrossSkill | sf_local040_eq_1_2 | PROVED | sql_equiv | 0.0 | 5.0 | yes | Bench/CrossSkill/Proven/sf_local040_eq_1_2.lean |
| CrossSkill | sf_local040_eq_1_3 | INCONCLUSIVE |  | 0.0 | 29.1 |  |  |
| CrossSkill | sf_local040_eq_2_3 | INCONCLUSIVE |  | 0.0 | 36.9 |  |  |
| CrossSkill | sf_local041_eq_0_1 | PROVED | sql_equiv | 0.0 | 4.5 | yes | Bench/CrossSkill/Proven/sf_local041_eq_0_1.lean |
| CrossSkill | sf_local041_eq_0_2 | PROVED | sql_equiv | 0.0 | 6.5 | yes | Bench/CrossSkill/Proven/sf_local041_eq_0_2.lean |
| CrossSkill | sf_local041_eq_0_3 | PROVED | sql_equiv | 0.0 | 6.4 | yes | Bench/CrossSkill/Proven/sf_local041_eq_0_3.lean |
| CrossSkill | sf_local041_eq_1_2 | PROVED | sql_equiv | 0.0 | 6.5 | yes | Bench/CrossSkill/Proven/sf_local041_eq_1_2.lean |
| CrossSkill | sf_local041_eq_1_3 | PROVED | sql_equiv | 0.0 | 6.4 | yes | Bench/CrossSkill/Proven/sf_local041_eq_1_3.lean |
| CrossSkill | sf_local041_eq_2_3 | PROVED | sql_equiv | 0.0 | 4.6 | yes | Bench/CrossSkill/Proven/sf_local041_eq_2_3.lean |
| CrossSkill | sf_local049_eq_0_1 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2333 | 88.9 |  |  |
| CrossSkill | sf_local049_eq_0_2 | INCONCLUSIVE | exhausted | 3.6459 | 314.6 |  |  |
| CrossSkill | sf_local049_eq_0_3 | ELAB_ERROR |  | 0.0 | 68.4 |  |  |
| CrossSkill | sf_local049_eq_1_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2286 | 110.3 |  |  |
| CrossSkill | sf_local049_eq_1_3 | ELAB_ERROR |  | 0.0 | 67.3 |  |  |
| CrossSkill | sf_local049_eq_2_3 | ELAB_ERROR |  | 0.0 | 67.0 |  |  |
| CrossSkill | sf_local050_eq_0_1 | ELAB_ERROR |  | 0.0 | 75.8 |  |  |
| CrossSkill | sf_local054_eq_0_1 | ELAB_ERROR |  | 0.0 | 80.1 |  |  |
| CrossSkill | sf_local054_eq_0_2 | ELAB_ERROR |  | 0.0 | 77.5 |  |  |
| CrossSkill | sf_local054_eq_0_3 | ELAB_ERROR |  | 0.0 | 89.1 |  |  |
| CrossSkill | sf_local054_eq_1_2 | ELAB_ERROR |  | 0.0 | 79.0 |  |  |
| CrossSkill | sf_local054_eq_1_3 | ELAB_ERROR |  | 0.0 | 82.6 |  |  |
| CrossSkill | sf_local054_eq_2_3 | ELAB_ERROR |  | 0.0 | 88.8 |  |  |
| CrossSkill | sf_local055_eq_0_1 | INCONCLUSIVE | exhausted | 0.6577 | 21.5 |  |  |
| CrossSkill | sf_local055_eq_0_2 | INCONCLUSIVE | exhausted | 0.8641 | 41.1 |  |  |
| CrossSkill | sf_local055_eq_0_3 | ELAB_ERROR |  | 0.0 | 235.4 |  |  |
| CrossSkill | sf_local055_eq_1_2 | INCONCLUSIVE | exhausted | 0.6927 | 23.7 |  |  |
| CrossSkill | sf_local055_eq_1_3 | ELAB_ERROR |  | 0.0 | 116.6 |  |  |
| CrossSkill | sf_local055_eq_2_3 | DISPROVED(unverified-artifact) | plausible_sql | 1.0954 | 145.9 | NO |  |
| CrossSkill | sf_local058_eq_0_1 | INCONCLUSIVE |  | 0.0 | 47.3 |  |  |
| CrossSkill | sf_local058_eq_0_2 | INCONCLUSIVE |  | 0.0 | 63.5 |  |  |
| CrossSkill | sf_local058_eq_0_3 | INCONCLUSIVE |  | 0.0 | 60.6 |  |  |
| CrossSkill | sf_local058_eq_1_2 | ELAB_ERROR |  | 0.0 | 525.9 |  |  |
| CrossSkill | sf_local058_eq_1_3 | PROVED | llm | 0.3809 | 41.7 | yes | Bench/CrossSkill/Proven/sf_local058_eq_1_3.lean |
| CrossSkill | sf_local058_eq_2_3 | INCONCLUSIVE | exhausted | 7.6316 | 528.6 |  |  |
| CrossSkill | sf_local059_eq_0_1 | INCONCLUSIVE | exhausted | 4.5729 | 360.6 |  |  |
| CrossSkill | sf_local059_eq_0_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.2701 | 38.8 | NO |  |
| CrossSkill | sf_local059_eq_0_3 | INCONCLUSIVE |  | 0.0 | 79.8 |  |  |
| CrossSkill | sf_local059_eq_1_2 | INCONCLUSIVE | exhausted | 3.9969 | 308.1 |  |  |
| CrossSkill | sf_local059_eq_1_3 | INCONCLUSIVE |  | 0.0 | 96.1 |  |  |
| CrossSkill | sf_local059_eq_2_3 | PROVED | sql_equiv | 0.0 | 5.4 | yes | Bench/CrossSkill/Proven/sf_local059_eq_2_3.lean |
| CrossSkill | sf_local060_eq_0_1 | ELAB_ERROR |  | 0.0 | 76.1 |  |  |
| CrossSkill | sf_local060_eq_0_2 | ELAB_ERROR |  | 0.0 | 75.8 |  |  |
| CrossSkill | sf_local060_eq_0_3 | ELAB_ERROR |  | 0.0 | 75.5 |  |  |
| CrossSkill | sf_local060_eq_1_2 | INCONCLUSIVE | exhausted | 0.6486 | 17.5 |  |  |
| CrossSkill | sf_local060_eq_1_3 | INCONCLUSIVE | exhausted | 0.6494 | 18.4 |  |  |
| CrossSkill | sf_local060_eq_2_3 | INCONCLUSIVE | exhausted | 0.7166 | 25.5 |  |  |
| CrossSkill | sf_local061_eq_0_1 | ELAB_ERROR |  | 0.0 | 78.9 |  |  |
| CrossSkill | sf_local061_eq_0_2 | ELAB_ERROR |  | 0.0 | 61.0 |  |  |
| CrossSkill | sf_local061_eq_0_3 | ELAB_ERROR |  | 0.0 | 78.2 |  |  |
| CrossSkill | sf_local061_eq_1_2 | ELAB_ERROR |  | 0.0 | 79.5 |  |  |
| CrossSkill | sf_local061_eq_1_3 | ELAB_ERROR |  | 0.0 | 78.2 |  |  |
| CrossSkill | sf_local061_eq_2_3 | ELAB_ERROR |  | 0.0 | 79.4 |  |  |
| CrossSkill | sf_local063_eq_0_1 | ELAB_ERROR |  | 0.0 | 85.3 |  |  |
| CrossSkill | sf_local063_eq_0_2 | ELAB_ERROR |  | 0.0 | 84.3 |  |  |
| CrossSkill | sf_local063_eq_0_3 | ELAB_ERROR |  | 0.0 | 84.0 |  |  |
| CrossSkill | sf_local063_eq_1_2 | INCONCLUSIVE | exhausted | 0.6612 | 19.0 |  |  |
| CrossSkill | sf_local063_eq_1_3 | INCONCLUSIVE | exhausted | 0.6696 | 19.3 |  |  |
| CrossSkill | sf_local063_eq_2_3 | INCONCLUSIVE | exhausted | 0.6902 | 21.5 |  |  |
| CrossSkill | sf_local065_eq_0_1 | INCONCLUSIVE |  | 0.0 | 25.4 |  |  |
| CrossSkill | sf_local065_eq_0_2 | INCONCLUSIVE |  | 0.0 | 33.4 |  |  |
| CrossSkill | sf_local065_eq_0_3 | INCONCLUSIVE |  | 0.0 | 37.9 |  |  |
| CrossSkill | sf_local065_eq_1_2 | INCONCLUSIVE |  | 0.0 | 31.4 |  |  |
| CrossSkill | sf_local065_eq_1_3 | INCONCLUSIVE |  | 0.0 | 26.8 |  |  |
| CrossSkill | sf_local065_eq_2_3 | INCONCLUSIVE |  | 0.0 | 33.0 |  |  |
| CrossSkill | sf_local066_eq_0_1 | INCONCLUSIVE |  | 0.0 | 122.1 |  |  |
| CrossSkill | sf_local066_eq_0_2 | INCONCLUSIVE |  | 0.0 | 58.4 |  |  |
| CrossSkill | sf_local066_eq_0_3 | INCONCLUSIVE |  | 0.0 | 133.3 |  |  |
| CrossSkill | sf_local066_eq_1_2 | INCONCLUSIVE |  | 0.0 | 78.7 |  |  |
| CrossSkill | sf_local066_eq_1_3 | INCONCLUSIVE |  | 0.0 | 195.4 |  |  |
| CrossSkill | sf_local066_eq_2_3 | INCONCLUSIVE |  | 0.0 | 63.8 |  |  |
| CrossSkill | sf_local067_eq_0_1 | INCONCLUSIVE | exhausted | 2.5182 | 190.0 |  |  |
| CrossSkill | sf_local067_eq_0_2 | ELAB_ERROR |  | 0.0 | 107.6 |  |  |
| CrossSkill | sf_local067_eq_1_2 | INCONCLUSIVE | exhausted | 0.7837 | 29.2 |  |  |
| CrossSkill | sf_local068_eq_0_1 | INCONCLUSIVE |  | 0.0 | 76.7 |  |  |
| CrossSkill | sf_local068_eq_0_2 | ELAB_ERROR |  | 0.0 | 33.0 |  |  |
| CrossSkill | sf_local068_eq_1_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2137 | 20.7 |  |  |
| CrossSkill | sf_local070_eq_0_2 | INCONCLUSIVE |  | 0.0 | 236.2 |  |  |
| CrossSkill | sf_local070_eq_1_3 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local072_eq_0_1 | ELAB_ERROR |  | 0.0 | 79.3 |  |  |
| CrossSkill | sf_local072_eq_0_2 | ELAB_ERROR |  | 0.0 | 80.7 |  |  |
| CrossSkill | sf_local072_eq_0_3 | ELAB_ERROR |  | 0.0 | 157.5 |  |  |
| CrossSkill | sf_local072_eq_1_2 | ELAB_ERROR |  | 0.0 | 80.8 |  |  |
| CrossSkill | sf_local072_eq_1_3 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local072_eq_2_3 | ELAB_ERROR |  | 0.0 | 119.0 |  |  |
| CrossSkill | sf_local073_eq_0_1 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local073_eq_0_2 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local073_eq_0_3 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local073_eq_1_2 | ELAB_ERROR |  | 0.0 | 214.2 |  |  |
| CrossSkill | sf_local073_eq_1_3 | ELAB_ERROR |  | 0.0 | 443.2 |  |  |
| CrossSkill | sf_local073_eq_2_3 | ELAB_ERROR |  | 0.0 | 265.7 |  |  |
| CrossSkill | sf_local074_eq_0_2 | ELAB_ERROR |  | 0.0 | 106.6 |  |  |
| CrossSkill | sf_local074_eq_0_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.2286 | 15.2 | NO |  |
| CrossSkill | sf_local074_eq_1_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.2497 | 14.3 | NO |  |
| CrossSkill | sf_local074_eq_1_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.239 | 13.2 | NO |  |
| CrossSkill | sf_local074_eq_2_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.2278 | 16.6 | NO |  |
| CrossSkill | sf_local077_eq_0_1 | DISPROVED(unverified-artifact) | plausible_sql | 0.2407 | 58.9 | NO |  |
| CrossSkill | sf_local077_eq_0_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.2293 | 63.2 | NO |  |
| CrossSkill | sf_local077_eq_0_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.2474 | 27.2 | NO |  |
| CrossSkill | sf_local077_eq_1_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.2624 | 55.5 | NO |  |
| CrossSkill | sf_local077_eq_1_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.3996 | 163.7 | NO |  |
| CrossSkill | sf_local077_eq_2_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.2794 | 98.6 | NO |  |
| CrossSkill | sf_local081_eq_0_1 | INCONCLUSIVE |  | 0.0 | 53.2 |  |  |
| CrossSkill | sf_local081_eq_0_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.3721 | 108.1 |  |  |
| CrossSkill | sf_local081_eq_0_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.3791 | 57.0 | NO |  |
| CrossSkill | sf_local081_eq_1_2 | INCONCLUSIVE |  | 0.0 | 45.7 |  |  |
| CrossSkill | sf_local081_eq_1_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.3228 | 49.7 | NO |  |
| CrossSkill | sf_local081_eq_2_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.3648 | 53.1 | NO |  |
| CrossSkill | sf_local085_eq_0_1 | PROVED | sql_equiv | 0.0 | 6.0 | yes | Bench/CrossSkill/Proven/sf_local085_eq_0_1.lean |
| CrossSkill | sf_local085_eq_0_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.223 | 84.2 |  |  |
| CrossSkill | sf_local085_eq_0_3 | INCONCLUSIVE |  | 0.0 | 110.3 |  |  |
| CrossSkill | sf_local085_eq_1_2 | INCONCLUSIVE |  | 0.0 | 65.6 |  |  |
| CrossSkill | sf_local085_eq_1_3 | INCONCLUSIVE |  | 0.0 | 93.8 |  |  |
| CrossSkill | sf_local085_eq_2_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2194 | 92.3 |  |  |
| CrossSkill | sf_local096_eq_0_1 | ELAB_ERROR |  | 0.0 | 70.8 |  |  |
| CrossSkill | sf_local096_eq_0_2 | ELAB_ERROR |  | 0.0 | 25.9 |  |  |
| CrossSkill | sf_local096_eq_0_3 | ELAB_ERROR |  | 0.0 | 165.7 |  |  |
| CrossSkill | sf_local096_eq_1_2 | ELAB_ERROR |  | 0.0 | 29.8 |  |  |
| CrossSkill | sf_local096_eq_1_3 | ELAB_ERROR |  | 0.0 | 165.9 |  |  |
| CrossSkill | sf_local096_eq_2_3 | DISPROVED(unverified-artifact) | plausible_sql | 1.6912 | 191.8 | NO |  |
| CrossSkill | sf_local098_eq_0_1 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2752 | 136.1 |  |  |
| CrossSkill | sf_local098_eq_0_2 | ELAB_ERROR |  | 0.0 | 209.4 |  |  |
| CrossSkill | sf_local098_eq_0_3 | INCONCLUSIVE |  | 0.0 | 113.2 |  |  |
| CrossSkill | sf_local098_eq_1_2 | INCONCLUSIVE |  | 0.0 | 126.5 |  |  |
| CrossSkill | sf_local098_eq_1_3 | INCONCLUSIVE |  | 0.0 | 236.0 |  |  |
| CrossSkill | sf_local098_eq_2_3 | ELAB_ERROR |  | 0.0 | 94.4 |  |  |
| CrossSkill | sf_local099_eq_0_1 | INCONCLUSIVE |  | 0.0 | 60.8 |  |  |
| CrossSkill | sf_local099_eq_0_2 | PROVED | sql_equiv | 0.0 | 5.1 | yes | Bench/CrossSkill/Proven/sf_local099_eq_0_2.lean |
| CrossSkill | sf_local099_eq_0_3 | ELAB_ERROR |  | 0.0 | 59.5 |  |  |
| CrossSkill | sf_local099_eq_1_2 | INCONCLUSIVE |  | 0.0 | 54.8 |  |  |
| CrossSkill | sf_local099_eq_1_3 | INCONCLUSIVE |  | 0.0 | 68.8 |  |  |
| CrossSkill | sf_local099_eq_2_3 | ELAB_ERROR |  | 0.0 | 59.6 |  |  |
| CrossSkill | sf_local100_eq_0_1 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local100_eq_0_2 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local100_eq_0_3 | TIMEOUT |  | 0.0 | 700.3 |  |  |
| CrossSkill | sf_local100_eq_1_2 | ELAB_ERROR |  | 0.0 | 92.8 |  |  |
| CrossSkill | sf_local100_eq_1_3 | ELAB_ERROR |  | 0.0 | 94.4 |  |  |
| CrossSkill | sf_local100_eq_2_3 | TIMEOUT |  | 0.0 | 700.3 |  |  |
| CrossSkill | sf_local114_eq_0_1 | INCONCLUSIVE |  | 0.0 | 96.8 |  |  |
| CrossSkill | sf_local114_eq_0_2 | ELAB_ERROR |  | 0.0 | 619.7 |  |  |
| CrossSkill | sf_local114_eq_0_3 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local114_eq_1_2 | TIMEOUT |  | 0.0 | 700.3 |  |  |
| CrossSkill | sf_local114_eq_1_3 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local114_eq_2_3 | ELAB_ERROR |  | 0.0 | 238.9 |  |  |
| CrossSkill | sf_local131_eq_0_1 | INCONCLUSIVE | exhausted | 0.7789 | 30.7 |  |  |
| CrossSkill | sf_local132_eq_0_1 | ELAB_ERROR |  | 0.0 | 116.2 |  |  |
| CrossSkill | sf_local132_eq_0_2 | ELAB_ERROR |  | 0.0 | 87.4 |  |  |
| CrossSkill | sf_local132_eq_0_3 | ELAB_ERROR |  | 0.0 | 481.4 |  |  |
| CrossSkill | sf_local132_eq_1_2 | ELAB_ERROR |  | 0.0 | 88.7 |  |  |
| CrossSkill | sf_local132_eq_1_3 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local132_eq_2_3 | ELAB_ERROR |  | 0.0 | 80.4 |  |  |
| CrossSkill | sf_local133_eq_0_1 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2804 | 102.2 |  |  |
| CrossSkill | sf_local133_eq_0_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2544 | 30.6 |  |  |
| CrossSkill | sf_local133_eq_0_3 | DISPROVED | plausible_sql | 0.2702 | 17.8 | yes(sqlglot-inconclusive) | Bench/CrossSkill/CounterExample/sf_local133_eq_0_3.lean |
| CrossSkill | sf_local133_eq_1_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2763 | 102.4 |  |  |
| CrossSkill | sf_local133_eq_1_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.4066 | 92.6 | NO |  |
| CrossSkill | sf_local133_eq_2_3 | DISPROVED | plausible_sql | 0.2627 | 16.9 | yes(sqlglot-inconclusive) | Bench/CrossSkill/CounterExample/sf_local133_eq_2_3.lean |
| CrossSkill | sf_local141_eq_0_1 | ELAB_ERROR |  | 0.0 | 109.8 |  |  |
| CrossSkill | sf_local156_eq_0_1 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local156_eq_0_2 | ELAB_ERROR |  | 0.0 | 158.8 |  |  |
| CrossSkill | sf_local156_eq_0_3 | ELAB_ERROR |  | 0.0 | 306.2 |  |  |
| CrossSkill | sf_local156_eq_1_2 | INCONCLUSIVE |  | 0.0 | 112.8 |  |  |
| CrossSkill | sf_local156_eq_1_3 | INCONCLUSIVE |  | 0.0 | 88.2 |  |  |
| CrossSkill | sf_local156_eq_2_3 | INCONCLUSIVE |  | 0.0 | 123.6 |  |  |
| CrossSkill | sf_local163_eq_0_1 | PROVED | sql_equiv | 0.0 | 5.8 | yes | Bench/CrossSkill/Proven/sf_local163_eq_0_1.lean |
| CrossSkill | sf_local163_eq_0_2 | INCONCLUSIVE |  | 0.0 | 281.4 |  |  |
| CrossSkill | sf_local163_eq_0_3 | INCONCLUSIVE |  | 0.0 | 99.0 |  |  |
| CrossSkill | sf_local163_eq_1_2 | INCONCLUSIVE |  | 0.0 | 87.1 |  |  |
| CrossSkill | sf_local163_eq_1_3 | ELAB_ERROR |  | 0.0 | 218.3 |  |  |
| CrossSkill | sf_local163_eq_2_3 | INCONCLUSIVE |  | 0.0 | 87.7 |  |  |
| CrossSkill | sf_local167_eq_0_1 | INCONCLUSIVE |  | 0.0 | 93.7 |  |  |
| CrossSkill | sf_local167_eq_0_2 | INCONCLUSIVE |  | 0.0 | 111.6 |  |  |
| CrossSkill | sf_local167_eq_0_3 | INCONCLUSIVE |  | 0.0 | 90.7 |  |  |
| CrossSkill | sf_local167_eq_1_2 | INCONCLUSIVE |  | 0.0 | 76.9 |  |  |
| CrossSkill | sf_local167_eq_1_3 | INCONCLUSIVE |  | 0.0 | 91.5 |  |  |
| CrossSkill | sf_local167_eq_2_3 | INCONCLUSIVE |  | 0.0 | 78.6 |  |  |
| CrossSkill | sf_local168_eq_0_1 | ELAB_ERROR |  | 0.0 | 87.5 |  |  |
| CrossSkill | sf_local168_eq_0_2 | ELAB_ERROR |  | 0.0 | 85.6 |  |  |
| CrossSkill | sf_local168_eq_0_3 | ELAB_ERROR |  | 0.0 | 424.4 |  |  |
| CrossSkill | sf_local168_eq_1_2 | INCONCLUSIVE |  | 0.0 | 99.5 |  |  |
| CrossSkill | sf_local168_eq_1_3 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local168_eq_2_3 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local169_eq_0_1 | ELAB_ERROR |  | 0.0 | 103.5 |  |  |
| CrossSkill | sf_local169_eq_0_2 | ELAB_ERROR |  | 0.0 | 128.0 |  |  |
| CrossSkill | sf_local169_eq_0_3 | ELAB_ERROR |  | 0.0 | 134.7 |  |  |
| CrossSkill | sf_local169_eq_1_2 | INCONCLUSIVE | exhausted | 0.6571 | 19.0 |  |  |
| CrossSkill | sf_local169_eq_1_3 | INCONCLUSIVE | exhausted | 0.6581 | 22.2 |  |  |
| CrossSkill | sf_local169_eq_2_3 | INCONCLUSIVE | exhausted | 0.6489 | 22.7 |  |  |
| CrossSkill | sf_local170_eq_0_1 | INCONCLUSIVE | exhausted | 0.6585 | 23.2 |  |  |
| CrossSkill | sf_local170_eq_0_2 | INCONCLUSIVE | exhausted | 0.6563 | 25.5 |  |  |
| CrossSkill | sf_local170_eq_0_3 | INCONCLUSIVE | exhausted | 0.6589 | 19.2 |  |  |
| CrossSkill | sf_local170_eq_1_2 | INCONCLUSIVE | exhausted | 0.6475 | 21.9 |  |  |
| CrossSkill | sf_local170_eq_1_3 | INCONCLUSIVE | exhausted | 0.6893 | 20.1 |  |  |
| CrossSkill | sf_local170_eq_2_3 | INCONCLUSIVE | exhausted | 0.6421 | 17.3 |  |  |
| CrossSkill | sf_local171_eq_0_1 | ELAB_ERROR |  | 0.0 | 86.3 |  |  |
| CrossSkill | sf_local171_eq_0_2 | ELAB_ERROR |  | 0.0 | 82.4 |  |  |
| CrossSkill | sf_local171_eq_1_2 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local196_eq_0_1 | ELAB_ERROR |  | 0.0 | 96.1 |  |  |
| CrossSkill | sf_local196_eq_0_2 | ELAB_ERROR |  | 0.0 | 221.7 |  |  |
| CrossSkill | sf_local196_eq_1_2 | ELAB_ERROR |  | 0.0 | 235.3 |  |  |
| CrossSkill | sf_local197_eq_0_1 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.3945 | 76.1 |  |  |
| CrossSkill | sf_local197_eq_0_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2598 | 141.4 |  |  |
| CrossSkill | sf_local197_eq_0_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.7699 | 88.6 | NO |  |
| CrossSkill | sf_local197_eq_1_2 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.29 | 222.2 |  |  |
| CrossSkill | sf_local197_eq_1_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.4618 | 54.0 | NO |  |
| CrossSkill | sf_local197_eq_2_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.2788 | 47.9 | NO |  |
| CrossSkill | sf_local198_eq_0_1 | INCONCLUSIVE |  | 0.0 | 51.6 |  |  |
| CrossSkill | sf_local198_eq_0_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.2569 | 47.0 | NO |  |
| CrossSkill | sf_local198_eq_0_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.3792 | 100.4 | NO |  |
| CrossSkill | sf_local198_eq_1_2 | INCONCLUSIVE |  | 0.0 | 52.8 |  |  |
| CrossSkill | sf_local198_eq_1_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2758 | 123.3 |  |  |
| CrossSkill | sf_local198_eq_2_3 | INCONCLUSIVE | exhausted | 1.57 | 132.3 |  |  |
| CrossSkill | sf_local201_eq_0_1 | ELAB_ERROR |  | 0.0 | 70.7 |  |  |
| CrossSkill | sf_local201_eq_0_2 | INCONCLUSIVE | exhausted | 0.6642 | 16.5 |  |  |
| CrossSkill | sf_local201_eq_0_3 | INCONCLUSIVE | exhausted | 1.1268 | 48.3 |  |  |
| CrossSkill | sf_local201_eq_1_2 | ELAB_ERROR |  | 0.0 | 70.3 |  |  |
| CrossSkill | sf_local201_eq_1_3 | ELAB_ERROR |  | 0.0 | 70.5 |  |  |
| CrossSkill | sf_local201_eq_2_3 | INCONCLUSIVE | exhausted | 0.6594 | 14.9 |  |  |
| CrossSkill | sf_local202_eq_0_1 | INCONCLUSIVE | exhausted | 6.1078 | 504.3 |  |  |
| CrossSkill | sf_local202_eq_0_2 | INCONCLUSIVE | exhausted | 5.1165 | 408.8 |  |  |
| CrossSkill | sf_local202_eq_0_3 | INCONCLUSIVE |  | 0.0 | 307.0 |  |  |
| CrossSkill | sf_local202_eq_1_2 | INCONCLUSIVE | exhausted | 4.069 | 293.7 |  |  |
| CrossSkill | sf_local202_eq_1_3 | ELAB_ERROR |  | 0.0 | 325.2 |  |  |
| CrossSkill | sf_local202_eq_2_3 | INCONCLUSIVE | exhausted | 3.1696 | 259.6 |  |  |
| CrossSkill | sf_local212_eq_0_1 | INCONCLUSIVE |  | 0.0 | 112.1 |  |  |
| CrossSkill | sf_local212_eq_0_2 | INCONCLUSIVE |  | 0.0 | 60.8 |  |  |
| CrossSkill | sf_local212_eq_0_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2323 | 22.5 |  |  |
| CrossSkill | sf_local212_eq_1_2 | INCONCLUSIVE |  | 0.0 | 89.4 |  |  |
| CrossSkill | sf_local212_eq_1_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.4598 | 28.6 |  |  |
| CrossSkill | sf_local212_eq_2_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.2305 | 22.0 |  |  |
| CrossSkill | sf_local219_eq_0_1 | INCONCLUSIVE |  | 0.0 | 128.4 |  |  |
| CrossSkill | sf_local219_eq_0_2 | INCONCLUSIVE |  | 0.0 | 158.9 |  |  |
| CrossSkill | sf_local219_eq_0_3 | INCONCLUSIVE |  | 0.0 | 139.5 |  |  |
| CrossSkill | sf_local219_eq_1_2 | PROVED | sql_equiv | 0.0 | 38.3 | yes | Bench/CrossSkill/Proven/sf_local219_eq_1_2.lean |
| CrossSkill | sf_local219_eq_1_3 | PROVED | sql_equiv | 0.0 | 37.2 | yes | Bench/CrossSkill/Proven/sf_local219_eq_1_3.lean |
| CrossSkill | sf_local219_eq_2_3 | PROVED | sql_equiv | 0.0 | 13.5 | yes | Bench/CrossSkill/Proven/sf_local219_eq_2_3.lean |
| CrossSkill | sf_local220_eq_0_1 | INCONCLUSIVE | exhausted | 0.6691 | 19.4 |  |  |
| CrossSkill | sf_local220_eq_0_2 | INCONCLUSIVE | exhausted | 0.6541 | 21.1 |  |  |
| CrossSkill | sf_local220_eq_0_3 | ELAB_ERROR |  | 0.0 | 366.0 |  |  |
| CrossSkill | sf_local220_eq_1_2 | INCONCLUSIVE | exhausted | 0.9285 | 40.6 |  |  |
| CrossSkill | sf_local220_eq_1_3 | ELAB_ERROR |  | 0.0 | 254.6 |  |  |
| CrossSkill | sf_local220_eq_2_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.7873 | 152.0 | NO |  |
| CrossSkill | sf_local221_eq_0_1 | INCONCLUSIVE |  | 0.0 | 56.2 |  |  |
| CrossSkill | sf_local221_eq_0_2 | PROVED | sql_equiv | 0.0 | 8.5 | yes | Bench/CrossSkill/Proven/sf_local221_eq_0_2.lean |
| CrossSkill | sf_local221_eq_0_3 | INCONCLUSIVE |  | 0.0 | 42.1 |  |  |
| CrossSkill | sf_local221_eq_1_2 | INCONCLUSIVE |  | 0.0 | 73.3 |  |  |
| CrossSkill | sf_local221_eq_1_3 | INCONCLUSIVE |  | 0.0 | 96.8 |  |  |
| CrossSkill | sf_local221_eq_2_3 | INCONCLUSIVE |  | 0.0 | 55.6 |  |  |
| CrossSkill | sf_local228_eq_0_1 | ELAB_ERROR |  | 0.0 | 78.1 |  |  |
| CrossSkill | sf_local228_eq_0_2 | ELAB_ERROR |  | 0.0 | 75.0 |  |  |
| CrossSkill | sf_local228_eq_0_3 | ELAB_ERROR |  | 0.0 | 78.0 |  |  |
| CrossSkill | sf_local228_eq_1_2 | ELAB_ERROR |  | 0.0 | 93.2 |  |  |
| CrossSkill | sf_local228_eq_1_3 | ELAB_ERROR |  | 0.0 | 90.7 |  |  |
| CrossSkill | sf_local228_eq_2_3 | ELAB_ERROR |  | 0.0 | 81.0 |  |  |
| CrossSkill | sf_local229_eq_0_1 | INCONCLUSIVE | exhausted | 2.4235 | 180.3 |  |  |
| CrossSkill | sf_local229_eq_0_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.3656 | 27.0 | NO |  |
| CrossSkill | sf_local229_eq_0_3 | ELAB_ERROR |  | 0.0 | 92.9 |  |  |
| CrossSkill | sf_local229_eq_1_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.3584 | 24.1 | NO |  |
| CrossSkill | sf_local229_eq_1_3 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local229_eq_2_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.5887 | 52.9 | NO |  |
| CrossSkill | sf_local230_eq_0_1 | ELAB_ERROR |  | 0.0 | 215.5 |  |  |
| CrossSkill | sf_local230_eq_0_2 | ELAB_ERROR |  | 0.0 | 133.4 |  |  |
| CrossSkill | sf_local230_eq_0_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.2386 | 111.1 | NO |  |
| CrossSkill | sf_local230_eq_1_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.2409 | 128.8 | NO |  |
| CrossSkill | sf_local230_eq_1_3 | ELAB_ERROR |  | 0.0 | 131.6 |  |  |
| CrossSkill | sf_local230_eq_2_3 | INCONCLUSIVE | exhausted | 0.731 | 28.1 |  |  |
| CrossSkill | sf_local253_eq_0_1 | DISPROVED(unverified-artifact) | plausible_sql | 0.2895 | 29.5 | NO |  |
| CrossSkill | sf_local253_eq_0_3 | DISPROVED(multiset; sqlglot could not run — unverified) | plausible_sql_bag | 0.298 | 51.9 |  |  |
| CrossSkill | sf_local253_eq_1_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.2705 | 37.4 | NO |  |
| CrossSkill | sf_local258_eq_0_1 | INCONCLUSIVE | exhausted | 0.6598 | 26.1 |  |  |
| CrossSkill | sf_local258_eq_0_2 | INCONCLUSIVE | exhausted | 0.651 | 29.7 |  |  |
| CrossSkill | sf_local258_eq_0_3 | INCONCLUSIVE | exhausted | 0.6718 | 29.4 |  |  |
| CrossSkill | sf_local258_eq_1_2 | INCONCLUSIVE | exhausted | 0.7008 | 30.2 |  |  |
| CrossSkill | sf_local258_eq_1_3 | INCONCLUSIVE | exhausted | 0.6756 | 30.7 |  |  |
| CrossSkill | sf_local258_eq_2_3 | INCONCLUSIVE | exhausted | 0.6608 | 27.4 |  |  |
| CrossSkill | sf_local259_eq_0_1 | INCONCLUSIVE | exhausted | 0.6649 | 36.2 |  |  |
| CrossSkill | sf_local259_eq_0_2 | INCONCLUSIVE | exhausted | 0.6371 | 24.5 |  |  |
| CrossSkill | sf_local259_eq_0_3 | INCONCLUSIVE | exhausted | 0.6969 | 38.6 |  |  |
| CrossSkill | sf_local259_eq_1_2 | INCONCLUSIVE | exhausted | 0.6811 | 26.5 |  |  |
| CrossSkill | sf_local259_eq_1_3 | INCONCLUSIVE | exhausted | 0.6859 | 37.8 |  |  |
| CrossSkill | sf_local259_eq_2_3 | INCONCLUSIVE | exhausted | 0.6601 | 26.2 |  |  |
| CrossSkill | sf_local262_eq_0_1 | INCONCLUSIVE |  | 0.0 | 353.2 |  |  |
| CrossSkill | sf_local262_eq_0_2 | INCONCLUSIVE |  | 0.0 | 218.1 |  |  |
| CrossSkill | sf_local262_eq_0_3 | ELAB_ERROR |  | 0.0 | 86.3 |  |  |
| CrossSkill | sf_local262_eq_1_2 | INCONCLUSIVE |  | 0.0 | 130.8 |  |  |
| CrossSkill | sf_local262_eq_1_3 | INCONCLUSIVE |  | 0.0 | 80.4 |  |  |
| CrossSkill | sf_local262_eq_2_3 | INCONCLUSIVE |  | 0.0 | 101.8 |  |  |
| CrossSkill | sf_local270_eq_0_1 | DISPROVED(unverified-artifact) | plausible_sql | 0.2646 | 68.3 | NO |  |
| CrossSkill | sf_local270_eq_0_2 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local270_eq_0_3 | TIMEOUT |  | 0.0 | 700.3 |  |  |
| CrossSkill | sf_local270_eq_1_2 | TIMEOUT |  | 0.0 | 700.4 |  |  |
| CrossSkill | sf_local270_eq_1_3 | TIMEOUT |  | 0.0 | 700.5 |  |  |
| CrossSkill | sf_local270_eq_2_3 | ELAB_ERROR |  | 0.0 | 438.9 |  |  |
| CrossSkill | sf_local273_eq_0_1 | INCONCLUSIVE | exhausted | 0.7926 | 28.8 |  |  |
| CrossSkill | sf_local273_eq_0_2 | INCONCLUSIVE | exhausted | 0.661 | 17.8 |  |  |
| CrossSkill | sf_local273_eq_0_3 | INCONCLUSIVE | exhausted | 0.6616 | 16.5 |  |  |
| CrossSkill | sf_local273_eq_1_2 | INCONCLUSIVE | exhausted | 0.6676 | 17.5 |  |  |
| CrossSkill | sf_local273_eq_1_3 | INCONCLUSIVE | exhausted | 0.6374 | 15.2 |  |  |
| CrossSkill | sf_local273_eq_2_3 | INCONCLUSIVE | exhausted | 0.6632 | 16.8 |  |  |
| CrossSkill | sf_local274_eq_0_1 | INCONCLUSIVE |  | 0.0 | 34.0 |  |  |
| CrossSkill | sf_local277_eq_0_1 | INCONCLUSIVE | exhausted | 0.6566 | 39.0 |  |  |
| CrossSkill | sf_local277_eq_0_2 | INCONCLUSIVE | exhausted | 0.656 | 28.6 |  |  |
| CrossSkill | sf_local277_eq_0_3 | INCONCLUSIVE | exhausted | 1.021 | 67.0 |  |  |
| CrossSkill | sf_local277_eq_1_2 | INCONCLUSIVE | exhausted | 0.648 | 17.0 |  |  |
| CrossSkill | sf_local277_eq_1_3 | INCONCLUSIVE | exhausted | 0.709 | 25.9 |  |  |
| CrossSkill | sf_local277_eq_2_3 | INCONCLUSIVE | exhausted | 4.3578 | 274.5 |  |  |
| CrossSkill | sf_local284_eq_0_1 | INCONCLUSIVE | exhausted | 1.9628 | 111.7 |  |  |
| CrossSkill | sf_local284_eq_0_2 | INCONCLUSIVE | exhausted | 0.6515 | 14.6 |  |  |
| CrossSkill | sf_local284_eq_0_3 | INCONCLUSIVE | exhausted | 1.4092 | 69.9 |  |  |
| CrossSkill | sf_local284_eq_1_2 | INCONCLUSIVE | exhausted | 0.6613 | 16.2 |  |  |
| CrossSkill | sf_local284_eq_1_3 | INCONCLUSIVE | exhausted | 2.0072 | 112.9 |  |  |
| CrossSkill | sf_local284_eq_2_3 | INCONCLUSIVE | exhausted | 0.7225 | 20.7 |  |  |
| CrossSkill | sf_local286_eq_0_1 | DISPROVED(unverified-artifact) | plausible_sql | 0.2767 | 93.4 | NO |  |
| CrossSkill | sf_local286_eq_0_2 | ELAB_ERROR |  | 0.0 | 71.8 |  |  |
| CrossSkill | sf_local286_eq_0_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.2873 | 89.2 | NO |  |
| CrossSkill | sf_local286_eq_1_2 | ELAB_ERROR |  | 0.0 | 146.2 |  |  |
| CrossSkill | sf_local286_eq_1_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.31 | 123.9 | NO |  |
| CrossSkill | sf_local286_eq_2_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.293 | 104.6 | NO |  |
| CrossSkill | sf_local297_eq_0_2 | DISPROVED(unverified-artifact) | plausible_sql | 0.3278 | 52.8 | NO |  |
| CrossSkill | sf_local301_eq_0_1 | INCONCLUSIVE |  | 0.0 | 51.9 |  |  |
| CrossSkill | sf_local301_eq_0_2 | INCONCLUSIVE |  | 0.0 | 58.5 |  |  |
| CrossSkill | sf_local301_eq_0_3 | INCONCLUSIVE |  | 0.0 | 30.9 |  |  |
| CrossSkill | sf_local301_eq_1_2 | INCONCLUSIVE |  | 0.0 | 54.8 |  |  |
| CrossSkill | sf_local301_eq_1_3 | INCONCLUSIVE |  | 0.0 | 50.9 |  |  |
| CrossSkill | sf_local301_eq_2_3 | INCONCLUSIVE |  | 0.0 | 63.7 |  |  |
| CrossSkill | sf_local310_eq_0_1 | PROVED | sql_equiv | 0.0 | 15.2 | yes | Bench/CrossSkill/Proven/sf_local310_eq_0_1.lean |
| CrossSkill | sf_local310_eq_0_2 | INCONCLUSIVE |  | 0.0 | 80.8 |  |  |
| CrossSkill | sf_local310_eq_0_3 | INCONCLUSIVE |  | 0.0 | 241.2 |  |  |
| CrossSkill | sf_local310_eq_1_2 | INCONCLUSIVE | exhausted | 3.4393 | 290.0 |  |  |
| CrossSkill | sf_local310_eq_1_3 | INCONCLUSIVE | exhausted | 4.1511 | 343.0 |  |  |
| CrossSkill | sf_local310_eq_2_3 | INCONCLUSIVE |  | 0.0 | 191.1 |  |  |
| CrossSkill | sf_local330_eq_0_2 | ELAB_ERROR |  | 0.0 | 84.6 |  |  |
| CrossSkill | sf_local330_eq_0_3 | ELAB_ERROR |  | 0.0 | 147.4 |  |  |
| CrossSkill | sf_local330_eq_2_3 | DISPROVED(unverified-artifact) | plausible_sql | 0.2596 | 55.5 | NO |  |
| CrossSkill | sf_local331_eq_0_1 | INCONCLUSIVE | exhausted | 0.6823 | 18.3 |  |  |
| CrossSkill | sf_local356_eq_0_1 | ELAB_ERROR |  | 0.0 | 81.7 |  |  |
| CrossSkill | sf_local356_eq_0_2 | ELAB_ERROR |  | 0.0 | 90.6 |  |  |
| CrossSkill | sf_local356_eq_1_2 | ELAB_ERROR |  | 0.0 | 81.3 |  |  |
| CrossSkill | sf_local358_eq_0_1 | INCONCLUSIVE |  | 0.0 | 111.6 |  |  |
| CrossSkill | sf_local358_eq_0_2 | INCONCLUSIVE |  | 0.0 | 141.1 |  |  |
| CrossSkill | sf_local358_eq_1_2 | INCONCLUSIVE |  | 0.0 | 64.4 |  |  |
| Literature | 0 | PROVED | llm | 0.2323 | 24.5 | yes | Bench/Literature/Proven/0.lean |
| Literature | 1 | PROVED | llm | 0.2228 | 18.4 | yes | Bench/Literature/Proven/1.lean |
| Literature | 10 | PROVED | llm | 0.2673 | 34.1 | yes | Bench/Literature/Proven/10.lean |
| Literature | 11_fix | DISPROVED | plausible_sql | 0.2047 | 12.4 | yes | Bench/Literature/CounterExample/11_fix.lean |
| Literature | 12 | SPURIOUS(real SQL bag-equal → model bug) | plausible_sql | 0.1972 | 15.0 |  |  |
| Literature | 13 | DISPROVED | plausible_sql | 0.1878 | 15.2 | yes | Bench/Literature/CounterExample/13.lean |
| Literature | 14 | PROVED | llm | 0.2628 | 23.6 | yes | Bench/Literature/Proven/14.lean |
| Literature | 15 | INCONCLUSIVE |  | 0.0 | 18.9 |  |  |
| Literature | 16 | PROVED | llm | 0.2439 | 17.7 | yes | Bench/Literature/Proven/16.lean |
| Literature | 17 | PROVED | sql_equiv | 0.0 | 5.0 | yes | Bench/Literature/Proven/17.lean |
| Literature | 18 | PROVED | llm | 0.298 | 17.0 | yes | Bench/Literature/Proven/18.lean |
| Literature | 19 | PROVED | llm | 0.2286 | 12.1 | yes | Bench/Literature/Proven/19.lean |
| Literature | 2 | PROVED | llm | 0.2187 | 12.4 | yes | Bench/Literature/Proven/2.lean |
| Literature | 20 | PROVED | llm | 0.2343 | 12.6 | yes | Bench/Literature/Proven/20.lean |
| Literature | 21 | PROVED | sql_equiv | 0.0 | 5.0 | yes | Bench/Literature/Proven/21.lean |
| Literature | 22 | PROVED | sql_equiv | 0.0 | 5.2 | yes | Bench/Literature/Proven/22.lean |
| Literature | 23 | PROVED | sql_equiv | 0.0 | 4.7 | yes | Bench/Literature/Proven/23.lean |
| Literature | 24 | PROVED | llm | 0.2779 | 15.0 | yes | Bench/Literature/Proven/24.lean |
| Literature | 25 | PROVED | sql_equiv | 0.0 | 5.2 | yes | Bench/Literature/Proven/25.lean |
| Literature | 26 | PROVED | llm | 0.2985 | 19.0 | yes | Bench/Literature/Proven/26.lean |
| Literature | 27 | PROVED | sql_equiv | 0.0 | 4.9 | yes | Bench/Literature/Proven/27.lean |
| Literature | 28 | PROVED | llm | 0.2372 | 11.0 | yes | Bench/Literature/Proven/28.lean |
| Literature | 29 | PROVED | llm | 0.2338 | 14.4 | yes | Bench/Literature/Proven/29.lean |
| Literature | 3 | PROVED | llm | 0.2261 | 13.6 | yes | Bench/Literature/Proven/3.lean |
| Literature | 30 | PROVED | sql_equiv | 0.0 | 6.7 | yes | Bench/Literature/Proven/30.lean |
| Literature | 31 | PROVED | llm | 0.2151 | 11.0 | yes | Bench/Literature/Proven/31.lean |
| Literature | 32 | PROVED | sql_equiv | 0.0 | 5.1 | yes | Bench/Literature/Proven/32.lean |
| Literature | 33 | PROVED | llm | 0.2213 | 14.0 | yes | Bench/Literature/Proven/33.lean |
| Literature | 34 | PROVED | llm | 0.2222 | 12.6 | yes | Bench/Literature/Proven/34.lean |
| Literature | 35 | PROVED | llm | 0.2173 | 14.5 | yes | Bench/Literature/Proven/35.lean |
| Literature | 36 | PROVED | sql_equiv | 0.0 | 5.4 | yes | Bench/Literature/Proven/36.lean |
| Literature | 37 | PROVED | sql_equiv | 0.0 | 4.9 | yes | Bench/Literature/Proven/37.lean |
| Literature | 38 | DISPROVED | plausible_sql | 0.1933 | 25.8 | yes | Bench/Literature/CounterExample/38.lean |
| Literature | 39 | INCONCLUSIVE |  | 0.0 | 57.4 |  |  |
| Literature | 4 | PROVED | llm | 0.817 | 48.5 | yes | Bench/Literature/Proven/4.lean |
| Literature | 40 | PROVED | sql_equiv | 0.0 | 21.9 | yes | Bench/Literature/Proven/40.lean |
| Literature | 41 | PROVED | sql_equiv | 0.0 | 7.1 | yes | Bench/Literature/Proven/41.lean |
| Literature | 42 | ELAB_ERROR |  | 0.0 | 61.7 |  |  |
| Literature | 43 | DISPROVED | plausible_sql | 0.2944 | 97.3 | yes | Bench/Literature/CounterExample/43.lean |
| Literature | 44 | DISPROVED | plausible_sql | 0.2427 | 50.1 | yes | Bench/Literature/CounterExample/44.lean |
| Literature | 45 | INCONCLUSIVE |  | 0.0 | 24.9 |  |  |
| Literature | 46 | ELAB_ERROR |  | 0.0 | 66.7 |  |  |
| Literature | 47 | ELAB_ERROR |  | 0.0 | 62.4 |  |  |
| Literature | 48 | INCONCLUSIVE | exhausted | 5.4038 | 383.1 |  |  |
| Literature | 49 | INCONCLUSIVE | exhausted | 3.2903 | 277.5 |  |  |
| Literature | 5 | DISPROVED | plausible_sql | 0.2196 | 19.5 | yes | Bench/Literature/CounterExample/5.lean |
| Literature | 50 | INCONCLUSIVE |  | 0.0 | 41.1 |  |  |
| Literature | 51 | INCONCLUSIVE |  | 0.0 | 47.7 |  |  |
| Literature | 52 | INCONCLUSIVE |  | 0.0 | 48.1 |  |  |
| Literature | 53 | INCONCLUSIVE |  | 0.0 | 85.3 |  |  |
| Literature | 54 | INCONCLUSIVE |  | 0.0 | 106.9 |  |  |
| Literature | 55 | PROVED | sql_equiv | 0.0 | 21.4 | yes | Bench/Literature/Proven/55.lean |
| Literature | 56 | PROVED | sql_equiv | 0.0 | 7.5 | yes | Bench/Literature/Proven/56.lean |
| Literature | 57 | ELAB_ERROR |  | 0.0 | 61.7 |  |  |
| Literature | 58 | DISPROVED | plausible_sql | 0.2823 | 95.3 | yes | Bench/Literature/CounterExample/58.lean |
| Literature | 59 | DISPROVED | plausible_sql | 0.188 | 15.0 | yes | Bench/Literature/CounterExample/59.lean |
| Literature | 6 | PROVED | llm | 0.285 | 23.4 | yes | Bench/Literature/Proven/6.lean |
| Literature | 60 | PROVED | sql_equiv | 0.0 | 5.1 | yes | Bench/Literature/Proven/60.lean |
| Literature | 61 | ELAB_ERROR |  | 0.0 | 45.6 |  |  |
| Literature | 62 | INCONCLUSIVE | exhausted | 5.2868 | 380.2 |  |  |
| Literature | 63 | INCONCLUSIVE |  | 0.0 | 21.7 |  |  |
| Literature | 7 | PROVED | llm | 0.7728 | 52.3 | yes | Bench/Literature/Proven/7.lean |
| Literature | 8 | DISPROVED | plausible_sql | 0.1788 | 10.9 | yes | Bench/Literature/CounterExample/8.lean |
| Literature | 9 | DISPROVED | plausible_sql | 0.2007 | 12.1 | yes | Bench/Literature/CounterExample/9.lean |