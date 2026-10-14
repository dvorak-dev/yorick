# Funeral notice page versions

El Día replaced `funebres2.htm` with `funebres3.htm`, and the markup changed from `li.c` to `article.notice`. Scrapes on or after 7 October 2026 read `funebres3.htm`. Dates through 6 October 2026 stay on `funebres2.htm`.

Both files still respond on 7 and 8 October 2026, and from 9 October only `funebres3.htm` exists. The cutoff is 7 October, not 9 October, because the new page on 8 October includes a notice (`NOE SZMULEWICZ`) that the old page does not. Existing rows are not rewritten. A recovery run can insert notices present only on `funebres3.htm`, and those new rows store that URL as `source_link`.
