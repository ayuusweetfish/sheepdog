pyftsubset raw/AaTianShiZhuYi.ttf --output-file=AaTianShiZhuYi.ttf --text=" 0123456789"`cat ../*.lua | perl -CIO -pe 's/[\p{ASCII} \N{U+2500}-\N{U+257F}]//g'`
pyftsubset raw/Mali-Regular.ttf --output-file=Mali-Regular.ttf --text=0123456789
