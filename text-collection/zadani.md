# Program na převedení kolekce textových dokumentů do vektorové reprezentace

Vstupem je textový soubor, jehož jednotlivé řádky reprezentují textové dokumenty (jeden řádek = jeden dokument). Řádky mají následující strukturu:
`C\tTEXT\n`

kde:
- `C` je třída dokumentu (několik znaků)
- `\t` je tabelátor
- `TEXT` je posloupnost libovolných znaků
reprezentující obsah dokumentu
- `\n` je znak konce řádku.

Z každého textu se odeberou HTML a obdobné tagy, entity, znaky, které nejsou písmeny (čísla, speciální znaky), a každý text se převede na tzv. bag-of-words reprezentaci, neboli posloupnost slov, kde pořadí není důležité. Z každého textu se následně vytvoří vektor, kde jednotlivé prvky vektoru (atributy) odpovídají jednotlivým slovům v celé kolekci a hodnoty ve vektoru budou záviset na výskytu daných slov v tomto textu. Hodnota (váha `i`-tého slova v `j`-tém dokumentu) je součinem dvou vah – lokální a globální, a normalizačního faktoru:
```math
wij = lij * gi * nj
```

Lokální váhy mohou být dvojího typu:
- `TP` (term presence) – přítomnost slova v dokumentu (`1` = ano, `0` = ne),
- `TF` (term frequency) – počet výskytů slova v dokumentu (`0` a víc).

Globální váha bude pouze jedna:
- `IDF` (inverse document frequency) – viz dále,
- je možnost globální váhu neuplatnit, v tom případě má tato váha hodnotu `1` (hodnota atributu pro daný dokument tak bude mít pouze hodnotu lokální váhy).

Poslední hodnotou vektoru je třída dokumentu. Každý dokument je tedy reprezentován vektorem o délce `N+1`, kde `N` je počet unikátních slov ve všech dokumentech (+1 je pro třídu dokumentu). Pokud to bude požadováno, mohou být ze všech textů odebrána slova, která mají četnost ve všech dokumentech dohromady nízkou (např. 1). Mohou být také odebrána slova, která mají určitý malý počet znaků.

Všechny informace, které ovlivňují způsob zpracování dokumentů, stejně jako jména vstupních a výstupních souborů budou předány jako parametry skriptu. Tyto parametry budou zpracovány s využitím libovolného modulu ze sítě CPAN. Pokud nejsou některé parametry zadány, bude se pracovat s nějakými implicitními hodnotami.