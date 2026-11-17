# Anexo da 098h5-ensaio: os 4 registros por semente, passo e dia (saida do tools/measure_economy; passo 0 = hoje, 2 = casas + 6 comerciantes sem mudar preco, 3 = + pao A 76, B 51, C 142)

## Semente 1, registro ALIMENTACAO (colunas: alive, dead, alive_a, alive_b, alive_c, food_market_a, food_market_b, food_market_c, food_npcs_a, food_npcs_b, food_npcs_c, merchants_hunger_max)
| passo | dia | alive | dead | alive_a | alive_b | alive_c | food_market_a | food_market_b | food_market_c | food_npcs_a | food_npcs_b | food_npcs_c | merchants_hunger_max |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 132 | 0 | 60 | 44 | 28 | 180 | 120 | 210 | 0 | 0 | 0 | 0 |
| 0 | 10 | 132 | 0 | 60 | 44 | 28 | 0 | 0 | 210 | 0 | 0 | 0 | 0 |
| 0 | 20 | 132 | 0 | 60 | 44 | 28 | 0 | 0 | 210 | 0 | 0 | 0 | 0 |
| 0 | 30 | 132 | 0 | 60 | 44 | 28 | 0 | 0 | 38 | 0 | 0 | 23 | 0 |
| 2 | 0 | 138 | 0 | 62 | 46 | 30 | 180 | 120 | 210 | 0 | 0 | 0 | 20 |
| 2 | 10 | 138 | 0 | 62 | 46 | 30 | 60 | 80 | 254 | 0 | 33 | 0 | 56 |
| 2 | 20 | 138 | 0 | 62 | 46 | 30 | 65 | 62 | 254 | 0 | 0 | 0 | 57 |
| 2 | 30 | 138 | 0 | 62 | 46 | 30 | 65 | 22 | 44 | 0 | 0 | 2 | 56 |
| 3 | 0 | 138 | 0 | 62 | 46 | 30 | 196 | 131 | 152 | 0 | 0 | 0 | 20 |
| 3 | 10 | 138 | 0 | 62 | 46 | 30 | 99 | 7 | 165 | 0 | 2 | 2 | 56 |
| 3 | 20 | 138 | 0 | 62 | 46 | 30 | 42 | 0 | 116 | 0 | 0 | 0 | 53 |
| 3 | 30 | 138 | 0 | 62 | 46 | 30 | 42 | 0 | 4 | 0 | 0 | 1 | 100 |

## Semente 1, registro PRODUCAO (colunas: sites, sites_running, made_total, used_total, made_bread, used_bread, made_grain, used_grain, made_flour, used_flour)
| passo | dia | sites | sites_running | made_total | used_total | made_bread | used_bread | made_grain | used_grain | made_flour | used_flour |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 14 | 14 | 3210 | 0 | 300 | 0 | 210 | 0 | 1670 | 0 |
| 0 | 10 | 14 | 0 | 4957 | 1704 | 522 | 322 | 946 | 930 | 1724 | 222 |
| 0 | 20 | 14 | 0 | 4957 | 1716 | 522 | 322 | 946 | 930 | 1724 | 222 |
| 0 | 30 | 14 | 0 | 4957 | 1868 | 522 | 464 | 946 | 937 | 1724 | 222 |
| 2 | 0 | 14 | 14 | 3210 | 0 | 300 | 0 | 210 | 0 | 1670 | 0 |
| 2 | 10 | 14 | 0 | 5541 | 2580 | 1074 | 614 | 970 | 954 | 1724 | 774 |
| 2 | 20 | 14 | 0 | 5577 | 2754 | 1110 | 739 | 970 | 954 | 1724 | 810 |
| 2 | 30 | 14 | 0 | 5577 | 3006 | 1110 | 977 | 970 | 964 | 1724 | 810 |
| 3 | 0 | 14 | 14 | 3179 | 0 | 269 | 0 | 210 | 0 | 1670 | 0 |
| 3 | 10 | 14 | 0 | 5148 | 2076 | 737 | 496 | 914 | 874 | 1724 | 468 |
| 3 | 20 | 14 | 0 | 5148 | 2202 | 737 | 612 | 914 | 875 | 1724 | 468 |
| 3 | 30 | 14 | 0 | 5148 | 2314 | 737 | 713 | 914 | 885 | 1724 | 468 |

## Semente 1, registro COMERCIO (colunas: led_trade, merchants_alive, merchants_travelling, merchants_held, merchants_trips, merchants_profit)
| passo | dia | led_trade | merchants_alive | merchants_travelling | merchants_held | merchants_trips | merchants_profit |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 0 | 10 | 13165 | 0 | 0 | 0 | 0 | 0 |
| 0 | 20 | 13175 | 0 | 0 | 0 | 0 | 0 |
| 0 | 30 | 15607 | 0 | 0 | 0 | 0 | 0 |
| 2 | 0 | 0 | 6 | 0 | 0 | 0 | 0 |
| 2 | 10 | 32439 | 6 | 0 | 0 | 27 | 1320 |
| 2 | 20 | 34532 | 6 | 0 | 0 | 30 | 1417 |
| 2 | 30 | 37790 | 6 | 0 | 0 | 30 | 1417 |
| 3 | 0 | 0 | 6 | 0 | 0 | 0 | 0 |
| 3 | 10 | 31433 | 6 | 0 | 0 | 33 | 1974 |
| 3 | 20 | 36855 | 6 | 0 | 0 | 45 | 2395 |
| 3 | 30 | 40042 | 6 | 0 | 0 | 46 | 2431 |

## Semente 1, registro RENDA (colunas: money_npc_alive, money_market, money_site, money_other, money_total, led_salary, led_trade, created)
| passo | dia | money_npc_alive | money_market | money_site | money_other | money_total | led_salary | led_trade | created |
|---|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 7920 | 9000 | 2800 | 0 | 19720 | 0 | 0 | 19720 |
| 0 | 10 | 6023 | 13657 | 40 | 0 | 19720 | 4392 | 13165 | 19720 |
| 0 | 20 | 6031 | 13659 | 30 | 0 | 19720 | 4400 | 13175 | 19720 |
| 0 | 30 | 3599 | 16091 | 30 | 0 | 19720 | 4400 | 15607 | 19720 |
| 2 | 0 | 9720 | 9000 | 2800 | 0 | 21520 | 0 | 0 | 21520 |
| 2 | 10 | 5272 | 16179 | 69 | 0 | 21520 | 5232 | 32439 | 21520 |
| 2 | 20 | 4773 | 16682 | 65 | 0 | 21520 | 5308 | 34532 | 21520 |
| 2 | 30 | 1541 | 19932 | 47 | 0 | 21520 | 5308 | 37790 | 21520 |
| 3 | 0 | 9720 | 9000 | 2800 | 0 | 21520 | 0 | 0 | 21520 |
| 3 | 10 | 6623 | 14853 | 44 | 0 | 21520 | 4688 | 31433 | 21520 |
| 3 | 20 | 4737 | 16741 | 42 | 0 | 21520 | 4700 | 36855 | 21520 |
| 3 | 30 | 1850 | 19628 | 42 | 0 | 21520 | 4700 | 40042 | 21520 |

## Semente 1, registro CONFERENCIA (colunas: problems, money_ok, goods_ok)
| passo | dia | problems | money_ok | goods_ok |
|---|---|---|---|---|
| 0 | 0 | 0 | 1 | 1 |
| 0 | 10 | 0 | 1 | 1 |
| 0 | 20 | 0 | 1 | 1 |
| 0 | 30 | 0 | 1 | 1 |
| 2 | 0 | 0 | 1 | 1 |
| 2 | 10 | 0 | 1 | 1 |
| 2 | 20 | 0 | 1 | 1 |
| 2 | 30 | 0 | 1 | 1 |
| 3 | 0 | 0 | 1 | 1 |
| 3 | 10 | 0 | 1 | 1 |
| 3 | 20 | 0 | 1 | 1 |
| 3 | 30 | 0 | 1 | 1 |

## Semente 2, registro ALIMENTACAO (colunas: alive, dead, alive_a, alive_b, alive_c, food_market_a, food_market_b, food_market_c, food_npcs_a, food_npcs_b, food_npcs_c, merchants_hunger_max)
| passo | dia | alive | dead | alive_a | alive_b | alive_c | food_market_a | food_market_b | food_market_c | food_npcs_a | food_npcs_b | food_npcs_c | merchants_hunger_max |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 132 | 0 | 60 | 44 | 28 | 180 | 120 | 210 | 0 | 0 | 0 | 0 |
| 0 | 10 | 132 | 0 | 60 | 44 | 28 | 0 | 89 | 210 | 0 | 17 | 0 | 0 |
| 0 | 20 | 132 | 0 | 60 | 44 | 28 | 0 | 77 | 210 | 0 | 0 | 0 | 0 |
| 0 | 30 | 132 | 0 | 60 | 44 | 28 | 0 | 77 | 65 | 0 | 0 | 19 | 0 |
| 2 | 0 | 138 | 0 | 62 | 46 | 30 | 180 | 120 | 210 | 0 | 0 | 0 | 20 |
| 2 | 10 | 138 | 0 | 62 | 46 | 30 | 80 | 90 | 238 | 0 | 32 | 0 | 55 |
| 2 | 20 | 138 | 0 | 62 | 46 | 30 | 53 | 37 | 238 | 0 | 0 | 0 | 55 |
| 2 | 30 | 138 | 0 | 62 | 46 | 30 | 53 | 29 | 21 | 0 | 0 | 2 | 55 |
| 3 | 0 | 138 | 0 | 62 | 46 | 30 | 196 | 131 | 152 | 0 | 0 | 0 | 20 |
| 3 | 10 | 138 | 0 | 62 | 47 | 29 | 37 | 0 | 170 | 0 | 6 | 0 | 87 |
| 3 | 20 | 138 | 0 | 62 | 46 | 30 | 22 | 0 | 114 | 0 | 0 | 0 | 55 |
| 3 | 30 | 138 | 0 | 62 | 46 | 30 | 22 | 0 | 0 | 0 | 0 | 1 | 55 |

## Semente 2, registro PRODUCAO (colunas: sites, sites_running, made_total, used_total, made_bread, used_bread, made_grain, used_grain, made_flour, used_flour)
| passo | dia | sites | sites_running | made_total | used_total | made_bread | used_bread | made_grain | used_grain | made_flour | used_flour |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 14 | 14 | 3210 | 0 | 300 | 0 | 210 | 0 | 1670 | 0 |
| 0 | 10 | 14 | 0 | 5175 | 2000 | 732 | 418 | 954 | 920 | 1724 | 432 |
| 0 | 20 | 14 | 0 | 5193 | 2105 | 750 | 482 | 954 | 929 | 1724 | 450 |
| 0 | 30 | 14 | 0 | 5193 | 2236 | 750 | 604 | 954 | 933 | 1724 | 450 |
| 2 | 0 | 14 | 14 | 3210 | 0 | 300 | 0 | 210 | 0 | 1670 | 0 |
| 2 | 10 | 14 | 0 | 5533 | 2602 | 1074 | 659 | 962 | 931 | 1724 | 774 |
| 2 | 20 | 14 | 0 | 5533 | 2725 | 1074 | 771 | 962 | 931 | 1724 | 774 |
| 2 | 30 | 14 | 0 | 5533 | 2951 | 1074 | 984 | 962 | 941 | 1724 | 774 |
| 3 | 0 | 14 | 14 | 3179 | 0 | 269 | 0 | 210 | 0 | 1670 | 0 |
| 3 | 10 | 14 | 0 | 5048 | 1954 | 653 | 450 | 898 | 882 | 1724 | 384 |
| 3 | 20 | 14 | 0 | 5048 | 2039 | 653 | 527 | 898 | 882 | 1724 | 384 |
| 3 | 30 | 14 | 0 | 5048 | 2153 | 653 | 630 | 898 | 892 | 1724 | 384 |

## Semente 2, registro COMERCIO (colunas: led_trade, merchants_alive, merchants_travelling, merchants_held, merchants_trips, merchants_profit)
| passo | dia | led_trade | merchants_alive | merchants_travelling | merchants_held | merchants_trips | merchants_profit |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 0 | 10 | 15844 | 0 | 0 | 0 | 0 | 0 |
| 0 | 20 | 16508 | 0 | 0 | 0 | 0 | 0 |
| 0 | 30 | 18812 | 0 | 0 | 0 | 0 | 0 |
| 2 | 0 | 0 | 6 | 0 | 0 | 0 | 0 |
| 2 | 10 | 31201 | 6 | 0 | 0 | 25 | 1112 |
| 2 | 20 | 32388 | 6 | 0 | 0 | 26 | 1160 |
| 2 | 30 | 37028 | 6 | 0 | 0 | 31 | 1283 |
| 3 | 0 | 0 | 6 | 0 | 0 | 0 | 0 |
| 3 | 10 | 28327 | 6 | 0 | 0 | 30 | 1522 |
| 3 | 20 | 32250 | 6 | 0 | 0 | 36 | 1877 |
| 3 | 30 | 35001 | 6 | 0 | 0 | 36 | 1877 |

## Semente 2, registro RENDA (colunas: money_npc_alive, money_market, money_site, money_other, money_total, led_salary, led_trade, created)
| passo | dia | money_npc_alive | money_market | money_site | money_other | money_total | led_salary | led_trade | created |
|---|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 7920 | 9000 | 2800 | 0 | 19720 | 0 | 0 | 19720 |
| 0 | 10 | 5560 | 14110 | 50 | 0 | 19720 | 4688 | 15844 | 19720 |
| 0 | 20 | 5262 | 14410 | 48 | 0 | 19720 | 4728 | 16508 | 19720 |
| 0 | 30 | 2979 | 16706 | 35 | 0 | 19720 | 4728 | 18812 | 19720 |
| 2 | 0 | 9720 | 9000 | 2800 | 0 | 21520 | 0 | 0 | 21520 |
| 2 | 10 | 5219 | 16237 | 64 | 0 | 21520 | 5224 | 31201 | 21520 |
| 2 | 20 | 4534 | 16932 | 54 | 0 | 21520 | 5244 | 32388 | 21520 |
| 2 | 30 | 1073 | 20400 | 47 | 0 | 21520 | 5244 | 37028 | 21520 |
| 3 | 0 | 9720 | 9000 | 2800 | 0 | 21520 | 0 | 0 | 21520 |
| 3 | 10 | 6696 | 14779 | 45 | 0 | 21520 | 4576 | 28327 | 21520 |
| 3 | 20 | 5479 | 15996 | 45 | 0 | 21520 | 4588 | 32250 | 21520 |
| 3 | 30 | 2728 | 18747 | 45 | 0 | 21520 | 4588 | 35001 | 21520 |

## Semente 2, registro CONFERENCIA (colunas: problems, money_ok, goods_ok)
| passo | dia | problems | money_ok | goods_ok |
|---|---|---|---|---|
| 0 | 0 | 0 | 1 | 1 |
| 0 | 10 | 0 | 1 | 1 |
| 0 | 20 | 0 | 1 | 1 |
| 0 | 30 | 0 | 1 | 1 |
| 2 | 0 | 0 | 1 | 1 |
| 2 | 10 | 0 | 1 | 1 |
| 2 | 20 | 0 | 1 | 1 |
| 2 | 30 | 0 | 1 | 1 |
| 3 | 0 | 0 | 1 | 1 |
| 3 | 10 | 0 | 1 | 1 |
| 3 | 20 | 0 | 1 | 1 |
| 3 | 30 | 0 | 1 | 1 |

## Semente 3, registro ALIMENTACAO (colunas: alive, dead, alive_a, alive_b, alive_c, food_market_a, food_market_b, food_market_c, food_npcs_a, food_npcs_b, food_npcs_c, merchants_hunger_max)
| passo | dia | alive | dead | alive_a | alive_b | alive_c | food_market_a | food_market_b | food_market_c | food_npcs_a | food_npcs_b | food_npcs_c | merchants_hunger_max |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 132 | 0 | 60 | 44 | 28 | 180 | 120 | 210 | 0 | 0 | 0 | 0 |
| 0 | 10 | 132 | 0 | 60 | 44 | 28 | 0 | 100 | 210 | 0 | 29 | 0 | 0 |
| 0 | 20 | 132 | 0 | 60 | 44 | 28 | 0 | 100 | 210 | 0 | 0 | 0 | 0 |
| 0 | 30 | 132 | 0 | 60 | 44 | 28 | 0 | 100 | 60 | 0 | 0 | 28 | 0 |
| 2 | 0 | 138 | 0 | 62 | 46 | 30 | 180 | 120 | 210 | 0 | 0 | 0 | 20 |
| 2 | 10 | 138 | 0 | 62 | 46 | 30 | 59 | 89 | 218 | 0 | 20 | 0 | 56 |
| 2 | 20 | 138 | 0 | 62 | 46 | 30 | 63 | 48 | 218 | 0 | 0 | 0 | 55 |
| 2 | 30 | 138 | 0 | 62 | 46 | 30 | 63 | 26 | 17 | 0 | 0 | 2 | 55 |
| 3 | 0 | 138 | 0 | 62 | 46 | 30 | 196 | 131 | 152 | 0 | 0 | 0 | 20 |
| 3 | 10 | 138 | 0 | 62 | 46 | 30 | 90 | 0 | 173 | 0 | 2 | 1 | 54 |
| 3 | 20 | 138 | 0 | 62 | 46 | 30 | 44 | 0 | 115 | 0 | 0 | 0 | 56 |
| 3 | 30 | 138 | 0 | 62 | 46 | 30 | 44 | 0 | 0 | 0 | 0 | 1 | 100 |

## Semente 3, registro PRODUCAO (colunas: sites, sites_running, made_total, used_total, made_bread, used_bread, made_grain, used_grain, made_flour, used_flour)
| passo | dia | sites | sites_running | made_total | used_total | made_bread | used_bread | made_grain | used_grain | made_flour | used_flour |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 14 | 14 | 3210 | 0 | 300 | 0 | 210 | 0 | 1670 | 0 |
| 0 | 10 | 14 | 0 | 5189 | 2013 | 762 | 419 | 938 | 902 | 1724 | 462 |
| 0 | 20 | 14 | 0 | 5207 | 2117 | 780 | 490 | 938 | 902 | 1724 | 480 |
| 0 | 30 | 14 | 0 | 5207 | 2246 | 780 | 609 | 938 | 907 | 1724 | 480 |
| 2 | 0 | 14 | 14 | 3210 | 0 | 300 | 0 | 210 | 0 | 1670 | 0 |
| 2 | 10 | 14 | 0 | 5503 | 2565 | 1044 | 646 | 962 | 937 | 1724 | 744 |
| 2 | 20 | 14 | 0 | 5533 | 2727 | 1074 | 764 | 962 | 937 | 1724 | 774 |
| 2 | 30 | 14 | 0 | 5537 | 2955 | 1074 | 975 | 962 | 947 | 1724 | 774 |
| 3 | 0 | 14 | 14 | 3179 | 0 | 269 | 0 | 210 | 0 | 1670 | 0 |
| 3 | 10 | 14 | 0 | 5128 | 2028 | 701 | 478 | 930 | 881 | 1724 | 432 |
| 3 | 20 | 14 | 0 | 5128 | 2144 | 701 | 585 | 930 | 881 | 1724 | 432 |
| 3 | 30 | 14 | 0 | 5128 | 2260 | 701 | 689 | 930 | 891 | 1724 | 432 |

## Semente 3, registro COMERCIO (colunas: led_trade, merchants_alive, merchants_travelling, merchants_held, merchants_trips, merchants_profit)
| passo | dia | led_trade | merchants_alive | merchants_travelling | merchants_held | merchants_trips | merchants_profit |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 0 | 10 | 16162 | 0 | 0 | 0 | 0 | 0 |
| 0 | 20 | 16752 | 0 | 0 | 0 | 0 | 0 |
| 0 | 30 | 19005 | 0 | 0 | 0 | 0 | 0 |
| 2 | 0 | 0 | 6 | 0 | 0 | 0 | 0 |
| 2 | 10 | 29825 | 6 | 0 | 0 | 23 | 1024 |
| 2 | 20 | 31898 | 6 | 0 | 0 | 26 | 1117 |
| 2 | 30 | 35715 | 6 | 0 | 0 | 28 | 1160 |
| 3 | 0 | 0 | 6 | 0 | 0 | 0 | 0 |
| 3 | 10 | 32084 | 6 | 0 | 0 | 36 | 2040 |
| 3 | 20 | 36760 | 6 | 0 | 0 | 44 | 2370 |
| 3 | 30 | 39930 | 6 | 0 | 0 | 45 | 2405 |

## Semente 3, registro RENDA (colunas: money_npc_alive, money_market, money_site, money_other, money_total, led_salary, led_trade, created)
| passo | dia | money_npc_alive | money_market | money_site | money_other | money_total | led_salary | led_trade | created |
|---|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 7920 | 9000 | 2800 | 0 | 19720 | 0 | 0 | 19720 |
| 0 | 10 | 5507 | 14180 | 33 | 0 | 19720 | 4696 | 16162 | 19720 |
| 0 | 20 | 5269 | 14406 | 45 | 0 | 19720 | 4720 | 16752 | 19720 |
| 0 | 30 | 3055 | 16635 | 30 | 0 | 19720 | 4728 | 19005 | 19720 |
| 2 | 0 | 9720 | 9000 | 2800 | 0 | 21520 | 0 | 0 | 21520 |
| 2 | 10 | 5231 | 16225 | 64 | 0 | 21520 | 5184 | 29825 | 21520 |
| 2 | 20 | 4623 | 16834 | 63 | 0 | 21520 | 5244 | 31898 | 21520 |
| 2 | 30 | 1255 | 20217 | 48 | 0 | 21520 | 5252 | 35715 | 21520 |
| 3 | 0 | 9720 | 9000 | 2800 | 0 | 21520 | 0 | 0 | 21520 |
| 3 | 10 | 6228 | 15240 | 52 | 0 | 21520 | 4680 | 32084 | 21520 |
| 3 | 20 | 4562 | 16906 | 52 | 0 | 21520 | 4692 | 36760 | 21520 |
| 3 | 30 | 1667 | 19806 | 47 | 0 | 21520 | 4692 | 39930 | 21520 |

## Semente 3, registro CONFERENCIA (colunas: problems, money_ok, goods_ok)
| passo | dia | problems | money_ok | goods_ok |
|---|---|---|---|---|
| 0 | 0 | 0 | 1 | 1 |
| 0 | 10 | 0 | 1 | 1 |
| 0 | 20 | 0 | 1 | 1 |
| 0 | 30 | 0 | 1 | 1 |
| 2 | 0 | 0 | 1 | 1 |
| 2 | 10 | 0 | 1 | 1 |
| 2 | 20 | 0 | 1 | 1 |
| 2 | 30 | 0 | 1 | 1 |
| 3 | 0 | 0 | 1 | 1 |
| 3 | 10 | 0 | 1 | 1 |
| 3 | 20 | 0 | 1 | 1 |
| 3 | 30 | 0 | 1 | 1 |

# Anexo B: dia 0, TODOS os bens x TODOS os destinos de cada origem (V = viavel, net >= 20 e margem >= 5%; M = marginal, net positivo abaixo disso; N = prejuizo no melhor lote; X = sem lote possivel). Origem = mercado do povoado; 'q' = melhor lote; 'net' = receita - risco - custo - tempo (moedas). Hoje = precos atuais; proposta = pao A 76, B 51, C 142.
```
===== out/table_today.txt
origem A | bem | ->B | ->C
  bread   | N q1 net-14 | N q1 net-14
  fabric  | N q1 net-14 | N q1 net-14
  flour   | sem lote (no_lot) | N q1 net-14
  grain   | N q1 net-14 | N q1 net-14
  metal   | N q1 net-15 | N q1 net-14
  ore     | N q1 net-14 | N q1 net-14
  plank   | N q1 net-14 | N q1 net-14
  tool    | N q1 net-16 | N q1 net-18
  wood    | N q1 net-14 | sem lote (no_lot)
  wool    | N q1 net-14 | N q1 net-14
   resumo A>B: viaveis=[] marginais=[] tempo=143 min
   resumo A>C: viaveis=[] marginais=[] tempo=124 min
origem B | bem | ->A | ->C
  bread   | N q1 net-14 | N q1 net-13
  fabric  | N q1 net-14 | N q1 net-13
  flour   | N q1 net-11 | N q1 net-10
  grain   | N q1 net-14 | N q1 net-13
  metal   | N q1 net-15 | N q1 net-13
  ore     | N q1 net-14 | N q1 net-13
  plank   | N q1 net-14 | N q1 net-13
  tool    | N q1 net-16 | N q1 net-16
  wood    | N q1 net-14 | sem lote (no_lot)
  wool    | N q1 net-14 | N q1 net-13
   resumo B>A: viaveis=[] marginais=[] tempo=143 min
   resumo B>C: viaveis=[] marginais=[] tempo=96 min
origem C | bem | ->A | ->B
  bread   | N q1 net-14 | N q1 net-13
  fabric  | N q1 net-14 | N q1 net-13
  flour   | N q1 net-14 | sem lote (no_lot)
  grain   | N q1 net-14 | N q1 net-13
  metal   | N q1 net-15 | N q1 net-14
  ore     | N q1 net-14 | N q1 net-13
  plank   | N q1 net-14 | N q1 net-13
  tool    | N q1 net-17 | N q1 net-15
  wood    | N q1 net-12 | N q1 net-11
  wool    | N q1 net-14 | N q1 net-13
   resumo C>A: viaveis=[] marginais=[] tempo=124 min
   resumo C>B: viaveis=[] marginais=[] tempo=96 min
===== out/table_proposal.txt
origem A | bem | ->B | ->C
  bread   | N q1 net-14 | V q22 net36
  fabric  | N q1 net-14 | N q1 net-14
  flour   | sem lote (no_lot) | N q1 net-14
  grain   | N q1 net-14 | N q1 net-14
  metal   | N q1 net-15 | N q1 net-14
  ore     | N q1 net-14 | N q1 net-14
  plank   | N q1 net-14 | N q1 net-14
  tool    | N q1 net-16 | N q1 net-18
  wood    | N q1 net-14 | sem lote (no_lot)
  wool    | N q1 net-14 | N q1 net-14
   resumo A>B: viaveis=[] marginais=[] tempo=143 min
   resumo A>C: viaveis=[(36, 'bread')] marginais=[] tempo=124 min
origem B | bem | ->A | ->C
  bread   | N q1 net-14 | V q16 net29
  fabric  | N q1 net-14 | N q1 net-13
  flour   | N q1 net-11 | N q1 net-10
  grain   | N q1 net-14 | N q1 net-13
  metal   | N q1 net-15 | N q1 net-13
  ore     | N q1 net-14 | N q1 net-13
  plank   | N q1 net-14 | N q1 net-13
  tool    | N q1 net-16 | N q1 net-16
  wood    | N q1 net-14 | sem lote (no_lot)
  wool    | N q1 net-14 | N q1 net-13
   resumo B>A: viaveis=[] marginais=[] tempo=143 min
   resumo B>C: viaveis=[(29, 'bread')] marginais=[] tempo=96 min
origem C | bem | ->A | ->B
  bread   | N q1 net-21 | N q1 net-20
  fabric  | N q1 net-14 | N q1 net-13
  flour   | N q1 net-14 | sem lote (no_lot)
  grain   | N q1 net-14 | N q1 net-13
  metal   | N q1 net-15 | N q1 net-14
  ore     | N q1 net-14 | N q1 net-13
  plank   | N q1 net-14 | N q1 net-13
  tool    | N q1 net-17 | N q1 net-15
  wood    | N q1 net-12 | N q1 net-11
  wool    | N q1 net-14 | N q1 net-13
   resumo C>A: viaveis=[] marginais=[] tempo=124 min
   resumo C>B: viaveis=[] marginais=[] tempo=96 min
```

# Anexo C: referencias por passo (saidas brutas em out/)
=== PASSO 0
  run_sim seed 1: 732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7 modulos=0
  run_sim seed 2: 3f852d2cdfc3d4171e6893b79b0a9908b364a11203bdb9db59b9f9057e084544 modulos=0
  oraculo: passam=2 falham=0 (contagem 132 falhou=False)
    intents   antigo 28802dfa9d06  novo 28802dfa9d06  IGUAL
    alarm     antigo 916683019e46  novo 916683019e46  IGUAL
    resumed   antigo a2b476e37a0c  novo a2b476e37a0c  IGUAL
    switches  antigo b4c379eaad55  novo b4c379eaad55  IGUAL
    talk      antigo a96d78a9a82f  novo a96d78a9a82f  IGUAL
    save      antigo 5c885dbc09ee  novo 5c885dbc09ee  IGUAL
    demote    antigo c5b515175b72  novo c5b515175b72  IGUAL
    starved   antigo d2533a12fd05  novo d2533a12fd05  IGUAL
    real_game antigo 48857919c5ff  novo 48857919c5ff  IGUAL
  soak sem economia seed 11: SOAK seed=11 days=30 economy=false reload=0 hash=2b0f8a2917c1cd0b6824079f894a03c1892f8659649cf176604fa3802a2eeb63 min_alive=132 max_idle_min=0 max_thinks=20 problems=0 foo
  measure seed 1: md5(77 colunas)=5e124e5eba8dd9b55327d1fb9f4def57 colunas=83 dias=30
=== PASSO 1
  run_sim seed 1: 732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7 modulos=0
  run_sim seed 2: 3f852d2cdfc3d4171e6893b79b0a9908b364a11203bdb9db59b9f9057e084544 modulos=0
  oraculo: passam=2 falham=0 (contagem 132 falhou=False)
    intents   antigo 28802dfa9d06  novo 28802dfa9d06  IGUAL
    alarm     antigo 916683019e46  novo 916683019e46  IGUAL
    resumed   antigo a2b476e37a0c  novo a2b476e37a0c  IGUAL
    switches  antigo b4c379eaad55  novo b4c379eaad55  IGUAL
    talk      antigo a96d78a9a82f  novo a96d78a9a82f  IGUAL
    save      antigo 5c885dbc09ee  novo 5c885dbc09ee  IGUAL
    demote    antigo c5b515175b72  novo c5b515175b72  IGUAL
    starved   antigo d2533a12fd05  novo d2533a12fd05  IGUAL
    real_game antigo 48857919c5ff  novo 48857919c5ff  IGUAL
  soak sem economia seed 11: SOAK seed=11 days=30 economy=false reload=0 hash=2b0f8a2917c1cd0b6824079f894a03c1892f8659649cf176604fa3802a2eeb63 min_alive=132 max_idle_min=0 max_thinks=20 problems=0 foo
  measure seed 1: md5(77 colunas)=5e124e5eba8dd9b55327d1fb9f4def57 colunas=83 dias=30
=== PASSO 2
  run_sim seed 1: 732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7 modulos=0
  run_sim seed 2: 3f852d2cdfc3d4171e6893b79b0a9908b364a11203bdb9db59b9f9057e084544 modulos=0
  oraculo: passam=1 falham=1 (contagem 132 falhou=True)
    intents   antigo 28802dfa9d06  novo 28802dfa9d06  IGUAL
    alarm     antigo 916683019e46  novo 916683019e46  IGUAL
    resumed   antigo a2b476e37a0c  novo a2b476e37a0c  IGUAL
    switches  antigo b4c379eaad55  novo b4c379eaad55  IGUAL
    talk      antigo a96d78a9a82f  novo a96d78a9a82f  IGUAL
    save      antigo 5c885dbc09ee  novo 5c885dbc09ee  IGUAL
    demote    antigo c5b515175b72  novo c5b515175b72  IGUAL
    starved   antigo d2533a12fd05  novo d2533a12fd05  IGUAL
    real_game antigo 48857919c5ff  novo aaf2aed10ce4  MUDOU
  soak sem economia seed 11: SOAK seed=11 days=30 economy=false reload=0 hash=b7f0a32f3235ad3f3a092c7418564c423071acd9151410676dc6d484b03df5e3 min_alive=135 max_idle_min=0 max_thinks=20 problems=30 fo
  measure seed 1: md5(77 colunas)=92dcc2468a483b23a63fc7bcdf5486ae colunas=83 dias=30
=== PASSO 3
  run_sim seed 1: 732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7 modulos=0
  run_sim seed 2: 3f852d2cdfc3d4171e6893b79b0a9908b364a11203bdb9db59b9f9057e084544 modulos=0
  oraculo: passam=1 falham=1 (contagem 132 falhou=True)
    intents   antigo 28802dfa9d06  novo 28802dfa9d06  IGUAL
    alarm     antigo 916683019e46  novo 916683019e46  IGUAL
    resumed   antigo a2b476e37a0c  novo a2b476e37a0c  IGUAL
    switches  antigo b4c379eaad55  novo b4c379eaad55  IGUAL
    talk      antigo a96d78a9a82f  novo a96d78a9a82f  IGUAL
    save      antigo 5c885dbc09ee  novo 5c885dbc09ee  IGUAL
    demote    antigo c5b515175b72  novo c5b515175b72  IGUAL
    starved   antigo d2533a12fd05  novo d2533a12fd05  IGUAL
    real_game antigo 48857919c5ff  novo aaf2aed10ce4  MUDOU
  soak sem economia seed 11: SOAK seed=11 days=30 economy=false reload=0 hash=b7f0a32f3235ad3f3a092c7418564c423071acd9151410676dc6d484b03df5e3 min_alive=135 max_idle_min=0 max_thinks=20 problems=30 fo
  measure seed 1: md5(77 colunas)=9de7b6c44e44d1527e716d7310bd18aa colunas=83 dias=30

# Anexo D: LISTA COMPLETA dos testes que falham na OPCAO A (passos i+ii: 6 casas + 3 linhas merchant; market_targets.json intacto)
Suite inteira (`tools/run_tests`, unit + integration + soak curtos, so --headless, 600 s): 286 arquivos, 2294 testes, 2245 passam, **41 falham em 19 arquivos**, 8 risky/pending. (a) = so o numero 132->138 ou `EXPECTED_POPULATION`; (b) = ajuste de logica sem enfraquecer asserção; (c) = referencia a regravar.
`tools/validate_data`, `tools/check_content_ids`, `tests/test_validate_data.sh`, `test_check_content_ids.sh`, `test_run_sim.sh` e `test_measure_economy.sh`: todos exit 0 (os dados novos passam nos validadores do projeto).

| Arquivo | Teste | Cat. | Causa e o que precisa |
|---|---|---|---|
| integration/test_npc_bodies_switch.gd | test_turning_the_bodies_on_later_brings_the_s0_behaviour_back | b | todos os Intents devem ser ACT_AT_PLACE; o comerciante emite MOVE_TO_PLACE (ir ao mercado); excluir comerciantes da asserção |
| integration/test_npc_bodies_switch.gd | test_turning_the_bodies_off_releases_every_intent_and_each_action_goes_on_abstractly | b | o Intent mais proximo e de um comerciante (acao diferente de `eat`/`sleep`) |
| integration/test_npc_buys_food.gd | test_the_hungry_merchant_with_bread_in_the_pack_eats_instead_of_buying_while_the_common_npc_still_buys | b | [0, false]: o lavrador (NPC comum) nao inicia `buy` com os 6 comerciantes reais no mundo; causa exata NAO investigada |
| integration/test_npc_s0_flow.gd | test_a_success_result_applies_the_effects_once_and_the_npc_thinks_again_within_a_minute | b | o NPC mais proximo do foco virou um comerciante (NPC 61): Intent MOVE_TO_PLACE em vez de ACT_AT_PLACE; escolher o mais proximo entre os NAO comerciantes |
| integration/test_npc_s0_flow.gd | test_entering_s0_in_the_middle_of_an_abstract_action_finishes_it_abstractly_and_the_next_one_has_an_intent | b | o mais proximo esta em `rest` (rotina do comerciante) e nao em `sleep`; idem |
| integration/test_npc_s0_flow.gd | test_the_closest_fifty_of_the_sixty_get_a_body | b | o A tem 62 moradores, nao 60 ("os 60 do assentamento A") |
| integration/test_npc_s0_flow.gd | test_the_same_sequence_with_a_focus_gives_the_same_world_and_the_module_validates | a | 132 -> 138 (test_npc_s0_flow l.402) |
| integration/test_npc_s0_reevaluation.gd | test_an_urgent_need_cancels_the_sleep_intent_and_the_s0_npc_reacts_in_the_same_minute_as_its_s1_twin | b | dos 50 com corpo, 2 sao comerciantes (`rest`, sem Intent de sono): 48 de 50; filtrar os comerciantes na contagem, sem afrouxar a asserção |
| integration/test_npc_s0_reevaluation.gd | test_the_cancelled_sleep_intent_leaves_no_partial_effect_while_the_s1_twin_gets_one | b | idem (48 de 50) |
| integration/test_npc_s0_reevaluation.gd | test_a_late_result_of_the_cancelled_intent_is_discarded_and_counted_and_changes_nothing | b | idem (48 de 50) |
| integration/test_npc_s0_reevaluation.gd | test_an_alarm_cancels_the_sleep_intent_and_the_s0_npcs_react_like_their_s1_twins | b | "Sanidade: dormindo": o NPC escolhido esta em `rest` (comerciante) |
| integration/test_npc_s0_reevaluation.gd | test_the_end_of_the_routine_block_swaps_the_long_action_in_the_same_minute_as_the_s1_twin | b | idem (`rest` no lugar de `sleep`) |
| integration/test_npc_s0_reevaluation.gd | test_a_death_with_a_pending_intent_releases_it_without_error_and_the_body_goes_back | b | idem (48 de 50) |
| integration/test_npc_s0_reevaluation.gd | test_the_same_busy_morning_gives_the_same_world_and_the_module_validates | a | 132 -> 138 (test_npc_s0_reevaluation l.404) |
| integration/test_npc_s0_social.gd | test_in_the_complete_real_game_with_bodies_the_notables_get_acquainted_in_the_evening_talks | a | 132 -> 138 (test_npc_s0_social, COUNT_ALIVE_TOTAL l.56) |
| integration/test_npc_split_oracle.gd | test_the_real_game_with_one_hundred_npcs_behaves_exactly_as_before_the_split | a/c | contagem via `EXPECTED_POPULATION` 138 E nova impressao `real_game` (48857919c5ff... -> aaf2aed10ce460e5...): regravar so depois da sua aprovacao |
| soak/npc_life/test_npc_life_7d.gd | test_seven_days_without_a_player_keep_every_invariant_and_the_run_is_reproducible | a | `EXPECTED_POPULATION` 138; o soak de 7 dias sem economia mantem os 138 vivos (max_idle 0): deve passar depois do numero |
| soak/npc_year/test_npc_year_short.gd | test_one_day_with_300_npcs_and_alternating_bodies_keeps_every_invariant | a | derivado de `EXPECTED_POPULATION` (414 = 138 x 3) |
| soak/npc_year/test_npc_year_short.gd | test_bad_data_and_a_bad_pattern_are_reported_and_zero_days_run_clean | a | idem (414 NPCs no texto esperado) |
| unit/test_alarm.gd | test_the_real_world_a_village_reacts_the_other_far_away_does_not_and_life_goes_on | b | "o povoado inteiro" tem 62 moradores no A, nao 60 |
| unit/test_game_economy_wiring.gd | test_the_default_game_has_the_markets_and_every_npc_has_an_account_with_the_initial_money | b | o comerciante (NPC 78, 1o do A) abre a conta com 300 (tipo `merchant`), o teste espera 60 (tipo `npc`) de todos |
| unit/test_npc_life_check_transit.gd | test_the_run_is_the_one_of_today_and_with_economy_builds_the_real_game_and_survives_a_reload | a | passa sozinho quando `EXPECTED_POPULATION` virar 138 (l.333) |
| unit/test_npc_memory.gd | test_the_real_world_has_the_kinds_loaded_and_notables_remember_through_a_day | a | 132 -> 138 (test_npc_memory l.851) |
| unit/test_npc_relations.gd | test_the_real_world_relations_decay_over_three_days_and_the_world_stays_valid | a | 132 -> 138 (test_npc_relations l.850) |
| unit/test_npc_s0_wiring.gd | test_without_the_parameters_the_lod_and_the_intents_stay_off | a | 132 -> 138 (test_npc_s0_wiring l.135) |
| unit/test_npc_s0_wiring.gd | test_the_host_exposes_the_npc_module_and_clears_it_on_a_world_without_modules | a | 132 -> 138 (test_npc_s0_wiring l.157) |
| unit/test_npc_setup.gd | test_from_dir_assembles_everything_the_module_needs_from_the_real_data | a | 132 -> 138 (l.51) |
| unit/test_npc_setup.gd | test_the_game_modules_create_the_population_only_when_they_receive_the_setup | a | 132 -> 138 (l.86) e o proximo id 133 -> 139 (l.87) |
| unit/test_npc_setup.gd | test_the_host_starts_a_new_game_with_the_population_when_it_gets_the_setup | a | 132 -> 138 (l.111) |
| unit/test_npc_setup.gd | test_the_world_the_game_app_started_when_the_project_opened_has_the_population | a | 132 -> 138 (l.130) |
| unit/test_npc_setup.gd | test_one_game_day_with_the_real_data_closes_with_nothing_wrong | a | [132,132] -> [138,138] (l.145) |
| unit/test_npc_tiers.gd | test_the_real_world_takes_forty_notables_refuses_the_next_and_lives_on_exactly_as_before | a | 132 -> 138 (test_npc_tiers l.475 e 487) |
| unit/test_population.gd | test_the_real_file_has_the_provisional_scale_by_settlement_and_occupation | a | `plan.total()` 132 -> 138 (l.85) |
| unit/test_population.gd | test_the_real_plan_builds_the_whole_population_with_valid_homes_and_work_places | a | `specs.size()` 132 -> 138 (l.186) |
| unit/test_population.gd | test_each_npc_gets_the_first_home_with_room_and_the_work_place_of_its_row | b | indices fixos de `specs` (59/60/99/103/104/131) e casas: A passa a ter 62 moradores e 14 casas (a_home_13 e 14), B comeca no 63o; reescrever os indices e as casas esperadas |
| unit/test_population.gd | test_a_plan_with_no_room_fails_as_a_data_error_and_spends_no_random_numbers | b | pede 61 lavradores no A esperando "60 vagas"; com a_home_13/14 o A tem 70 vagas: trocar para 71 e "70 vaga" |
| unit/test_population.gd | test_a_new_game_creates_the_whole_population_in_order_and_it_is_valid | a | contagens 132 -> 138 e ids 1..132 -> 1..138 (l.349-351) |
| unit/test_population.gd | test_the_populated_world_survives_a_save_and_load_without_creating_anyone_again | a | 132 -> 138 (l.390) |
| unit/test_population.gd | test_a_plan_that_does_not_fit_creates_nobody_logs_the_error_and_reports_it | b | idem: 61 lavradores agora CABEM no A (70 vagas); usar 71 |
| unit/test_settlements_data.gd | test_each_settlement_has_the_places_the_contract_asks_for_and_room_for_the_100_npcs | b | constantes HOMES_A/B/C 12/9/8 -> 14/11/10 (e a soma de vagas): e numero, mas de CASAS, fora do texto da A2 |
| unit/test_social_actions.gd | test_the_real_world_notables_get_acquainted_in_the_evening_talks_and_the_world_stays_valid | a | 132 -> 138 (test_social_actions l.564) |

Resumo: (a) 23 (inclui o oraculo, que tambem e (c)); (b) 18. Referencias (c) a regravar so depois da aprovacao: oraculo `real_game` 48857919c5ff...(48857919c5ffce261b0bcfff4e933785adcd5085b6d63cb2f0802e0f81e5e1b4) -> aaf2aed10ce460e57d38b05c6273fea5bffa837537655bf837f4d64cefff4e22; soak 30 d sem economia (semente 11) 2b0f8a29...(2b0f8a2917c1cd0b6824079f894a03c1892f8659649cf176604fa3802a2eeb63) -> b7f0a32f3235ad3f3a092c7418564c423071acd9151410676dc6d484b03df5e3 (vivos minimo 135: o soak LONGO sem economia perde 3 NPCs; o de 7 dias mantem 138); soak 30 d com economia semente 1 64f1a2af0d79... -> c1379311abceb89dcb83cf592af8f886b655a8b0ac1b34ddfcd095297c652bd3; EXPECTED_POPULATION 132 -> 138.

# Anexo E: os diffs EXATOS dos dados propostos (só na cópia; NADA foi editado no repositório)

## E1. `data/world/places.json` (as 6 casas; opção A e B)
```diff
--- hoje/places.json
+++ proposto/places.json
@@ -21,6 +21,8 @@
 	{"id": "a_home_10", "settlement_id": "test_settlement_a", "kind": "home", "x_cm": 29900, "z_cm": 57000, "capacity": 5},
 	{"id": "a_home_11", "settlement_id": "test_settlement_a", "kind": "home", "x_cm": 31300, "z_cm": 57000, "capacity": 5},
 	{"id": "a_home_12", "settlement_id": "test_settlement_a", "kind": "home", "x_cm": 32700, "z_cm": 57000, "capacity": 5},
+	{"id": "a_home_13", "settlement_id": "test_settlement_a", "kind": "home", "x_cm": 28500, "z_cm": 58400, "capacity": 5},
+	{"id": "a_home_14", "settlement_id": "test_settlement_a", "kind": "home", "x_cm": 29900, "z_cm": 58400, "capacity": 5},
 	{"id": "a_work_06", "settlement_id": "test_settlement_a", "kind": "work", "x_cm": 34100, "z_cm": 57000, "capacity": 12},
 	{"id": "a_work_07", "settlement_id": "test_settlement_a", "kind": "work", "x_cm": 35500, "z_cm": 57000, "capacity": 12},
 	{"id": "b_work_01", "settlement_id": "test_settlement_b", "kind": "work", "x_cm": 77900, "z_cm": 63900, "capacity": 8},
@@ -43,6 +45,8 @@
 	{"id": "b_work_07", "settlement_id": "test_settlement_b", "kind": "work", "x_cm": 79300, "z_cm": 69500, "capacity": 8},
 	{"id": "b_work_08", "settlement_id": "test_settlement_b", "kind": "work", "x_cm": 80700, "z_cm": 69500, "capacity": 8},
 	{"id": "b_home_09", "settlement_id": "test_settlement_b", "kind": "home", "x_cm": 82100, "z_cm": 69500, "capacity": 5},
+	{"id": "b_home_10", "settlement_id": "test_settlement_b", "kind": "home", "x_cm": 77900, "z_cm": 70900, "capacity": 5},
+	{"id": "b_home_11", "settlement_id": "test_settlement_b", "kind": "home", "x_cm": 79300, "z_cm": 70900, "capacity": 5},
 	{"id": "c_work_01", "settlement_id": "test_settlement_c", "kind": "work", "x_cm": 53900, "z_cm": 83900, "capacity": 8},
 	{"id": "c_work_02", "settlement_id": "test_settlement_c", "kind": "work", "x_cm": 55300, "z_cm": 83900, "capacity": 8},
 	{"id": "c_work_03", "settlement_id": "test_settlement_c", "kind": "work", "x_cm": 56700, "z_cm": 83900, "capacity": 8},
@@ -58,5 +62,7 @@
 	{"id": "c_home_05", "settlement_id": "test_settlement_c", "kind": "home", "x_cm": 53900, "z_cm": 88100, "capacity": 5},
 	{"id": "c_home_06", "settlement_id": "test_settlement_c", "kind": "home", "x_cm": 55300, "z_cm": 88100, "capacity": 5},
 	{"id": "c_home_07", "settlement_id": "test_settlement_c", "kind": "home", "x_cm": 56700, "z_cm": 88100, "capacity": 5},
-	{"id": "c_home_08", "settlement_id": "test_settlement_c", "kind": "home", "x_cm": 58100, "z_cm": 88100, "capacity": 5}
+	{"id": "c_home_08", "settlement_id": "test_settlement_c", "kind": "home", "x_cm": 58100, "z_cm": 88100, "capacity": 5},
+	{"id": "c_home_09", "settlement_id": "test_settlement_c", "kind": "home", "x_cm": 53900, "z_cm": 89500, "capacity": 5},
+	{"id": "c_home_10", "settlement_id": "test_settlement_c", "kind": "home", "x_cm": 55300, "z_cm": 89500, "capacity": 5}
 ]
```

## E2. `data/population.json` (os 3 `merchant`; opção A e B)
```diff
--- hoje/population.json
+++ proposto/population.json
@@ -6,6 +6,7 @@
 	{"id": "pop_a_artisan_2", "settlement_id": "test_settlement_a", "occupation_id": "artisan", "count": 6, "work_place_id": "a_work_05"},
 	{"id": "pop_a_guard", "settlement_id": "test_settlement_a", "occupation_id": "guard", "count": 8, "work_place_id": "a_work_06"},
 	{"id": "pop_a_innkeeper", "settlement_id": "test_settlement_a", "occupation_id": "innkeeper", "count": 6, "work_place_id": "a_work_07"},
+	{"id": "pop_a_merchant", "settlement_id": "test_settlement_a", "occupation_id": "merchant", "count": 2, "work_place_id": "a_market_01"},
 	{"id": "pop_b_farmer_1", "settlement_id": "test_settlement_b", "occupation_id": "farmer", "count": 8, "work_place_id": "b_work_01"},
 	{"id": "pop_b_farmer_2", "settlement_id": "test_settlement_b", "occupation_id": "farmer", "count": 8, "work_place_id": "b_work_02"},
 	{"id": "pop_b_lumberjack", "settlement_id": "test_settlement_b", "occupation_id": "lumberjack", "count": 8, "work_place_id": "b_work_03"},
@@ -14,9 +15,11 @@
 	{"id": "pop_b_shepherd", "settlement_id": "test_settlement_b", "occupation_id": "shepherd", "count": 4, "work_place_id": "b_work_06"},
 	{"id": "pop_b_guard", "settlement_id": "test_settlement_b", "occupation_id": "guard", "count": 5, "work_place_id": "b_work_07"},
 	{"id": "pop_b_innkeeper", "settlement_id": "test_settlement_b", "occupation_id": "innkeeper", "count": 3, "work_place_id": "b_work_08"},
+	{"id": "pop_b_merchant", "settlement_id": "test_settlement_b", "occupation_id": "merchant", "count": 2, "work_place_id": "b_market_01"},
 	{"id": "pop_c_miner", "settlement_id": "test_settlement_c", "occupation_id": "miner", "count": 8, "work_place_id": "c_work_01"},
 	{"id": "pop_c_artisan_1", "settlement_id": "test_settlement_c", "occupation_id": "artisan", "count": 6, "work_place_id": "c_work_02"},
 	{"id": "pop_c_artisan_2", "settlement_id": "test_settlement_c", "occupation_id": "artisan", "count": 6, "work_place_id": "c_work_03"},
 	{"id": "pop_c_guard", "settlement_id": "test_settlement_c", "occupation_id": "guard", "count": 5, "work_place_id": "c_work_04"},
-	{"id": "pop_c_innkeeper", "settlement_id": "test_settlement_c", "occupation_id": "innkeeper", "count": 3, "work_place_id": "c_work_05"}
+	{"id": "pop_c_innkeeper", "settlement_id": "test_settlement_c", "occupation_id": "innkeeper", "count": 3, "work_place_id": "c_work_05"},
+	{"id": "pop_c_merchant", "settlement_id": "test_settlement_c", "occupation_id": "merchant", "count": 2, "work_place_id": "c_market_01"}
 ]
```

## E3. `data/economy/market_targets.json` (SÓ a opção B: o pão de 3 pares; a opção A NÃO toca este arquivo)
```diff
--- hoje/market_targets.json
+++ proposto/market_targets.json
@@ -1,7 +1,7 @@
 [
 	{"id": "mt_test_settlement_a_grain", "settlement_id": "test_settlement_a", "good_id": "grain", "target_stock": 120, "initial_stock": 120, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_a_flour", "settlement_id": "test_settlement_a", "good_id": "flour", "target_stock": 40, "initial_stock": 40, "buy_cap_bp": 20000},
-	{"id": "mt_test_settlement_a_bread", "settlement_id": "test_settlement_a", "good_id": "bread", "target_stock": 60, "initial_stock": 60, "buy_cap_bp": 20000},
+	{"id": "mt_test_settlement_a_bread", "settlement_id": "test_settlement_a", "good_id": "bread", "target_stock": 60, "initial_stock": 76, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_a_wood", "settlement_id": "test_settlement_a", "good_id": "wood", "target_stock": 60, "initial_stock": 60, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_a_plank", "settlement_id": "test_settlement_a", "good_id": "plank", "target_stock": 30, "initial_stock": 30, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_a_ore", "settlement_id": "test_settlement_a", "good_id": "ore", "target_stock": 10, "initial_stock": 10, "buy_cap_bp": 20000},
@@ -11,7 +11,7 @@
 	{"id": "mt_test_settlement_a_fabric", "settlement_id": "test_settlement_a", "good_id": "fabric", "target_stock": 25, "initial_stock": 25, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_b_grain", "settlement_id": "test_settlement_b", "good_id": "grain", "target_stock": 80, "initial_stock": 80, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_b_flour", "settlement_id": "test_settlement_b", "good_id": "flour", "target_stock": 810, "initial_stock": 1620, "buy_cap_bp": 20000},
-	{"id": "mt_test_settlement_b_bread", "settlement_id": "test_settlement_b", "good_id": "bread", "target_stock": 40, "initial_stock": 40, "buy_cap_bp": 20000},
+	{"id": "mt_test_settlement_b_bread", "settlement_id": "test_settlement_b", "good_id": "bread", "target_stock": 40, "initial_stock": 51, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_b_wood", "settlement_id": "test_settlement_b", "good_id": "wood", "target_stock": 40, "initial_stock": 40, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_b_plank", "settlement_id": "test_settlement_b", "good_id": "plank", "target_stock": 21, "initial_stock": 21, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_b_ore", "settlement_id": "test_settlement_b", "good_id": "ore", "target_stock": 10, "initial_stock": 10, "buy_cap_bp": 20000},
@@ -21,7 +21,7 @@
 	{"id": "mt_test_settlement_b_fabric", "settlement_id": "test_settlement_b", "good_id": "fabric", "target_stock": 30, "initial_stock": 30, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_c_grain", "settlement_id": "test_settlement_c", "good_id": "grain", "target_stock": 10, "initial_stock": 10, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_c_flour", "settlement_id": "test_settlement_c", "good_id": "flour", "target_stock": 10, "initial_stock": 10, "buy_cap_bp": 20000},
-	{"id": "mt_test_settlement_c_bread", "settlement_id": "test_settlement_c", "good_id": "bread", "target_stock": 200, "initial_stock": 200, "buy_cap_bp": 20000},
+	{"id": "mt_test_settlement_c_bread", "settlement_id": "test_settlement_c", "good_id": "bread", "target_stock": 200, "initial_stock": 142, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_c_wood", "settlement_id": "test_settlement_c", "good_id": "wood", "target_stock": 270, "initial_stock": 540, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_c_plank", "settlement_id": "test_settlement_c", "good_id": "plank", "target_stock": 15, "initial_stock": 15, "buy_cap_bp": 20000},
 	{"id": "mt_test_settlement_c_ore", "settlement_id": "test_settlement_c", "good_id": "ore", "target_stock": 60, "initial_stock": 60, "buy_cap_bp": 20000},
```
