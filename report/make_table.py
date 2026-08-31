"""Build report/results_table.tex from the Stata regression-suite output.

Run from the repository root:  python report/make_table.py

The generated file contains a complete table float, which main.tex pulls in
with a single top-level \\input.  Do not edit results_table.tex by hand.
"""

import csv

BS = chr(92)  # backslash, so this source stays free of escape headaches

BASELINE = 'tests/results/baseline_results.csv'
MERGED = 'tests/results/merged_results.csv'
OUT = 'report/results_table.tex'


def load(path):
    with open(path, newline='') as f:
        return {r['test']: r for r in csv.DictReader(f)}


def num(s, d=4):
    """Format one numeric cell; '.' or empty becomes an en-dash placeholder."""
    if s in ('', '.', None):
        return '--'
    v = float(s)
    if v != 0 and (abs(v) < 1e-4 or abs(v) >= 1e6):
        mant, exp = ('%.2e' % v).split('e')
        return '$%s%stimes 10^{%d}$' % (mant, BS, int(exp))
    return ('%.' + str(d) + 'f') % v


def jcell(r):
    """J statistic with its degrees of freedom in parentheses."""
    j = num(r['Jval'])
    if j == '--':
        return '--'
    df = r['J_df']
    df = '--' if df in ('', '.') else str(int(float(df)))
    return '%s (%s)' % (j, df)


PREAMBLE = r"""\begin{table}[htbp]
\centering
\caption{Baseline versus merged candidate, 29 regression tests}
\label{tab:results}
\footnotesize
\setlength{\tabcolsep}{4pt}
\begin{tabular}{l cc cc cc cc}
\toprule
 & \multicolumn{2}{c}{Return code} & \multicolumn{2}{c}{Coefficient}
 & \multicolumn{2}{c}{Std.\ error} & \multicolumn{2}{c}{$J$ (df)} \\
\cmidrule(lr){2-3}\cmidrule(lr){4-5}\cmidrule(lr){6-7}\cmidrule(lr){8-9}
Test & Base & Merg & Base & Merg & Base & Merg & Base & Merg \\
\midrule
"""

POSTAMBLE = r"""
\bottomrule
\end{tabular}

\vspace{0.6em}
\begin{minipage}{\textwidth}
\footnotesize
\resultsnotes % defined in main.tex just before the \input
\end{minipage}
\end{table}
"""


def main():
    base, merg = load(BASELINE), load(MERGED)
    rows = []
    for k in base:
        b, m = base[k], merg[k]
        cells = [
            k.replace('_', BS + '_'),
            b['rc'], m['rc'],
            num(b['b']), num(m['b']),
            num(b['se']), num(m['se']),
            jcell(b), jcell(m),
        ]
        rows.append(' & '.join(cells) + ' ' + BS + BS)

    with open(OUT, 'w', newline='') as f:
        f.write(PREAMBLE + '\n'.join(rows) + POSTAMBLE)
    print('wrote %s (%d rows)' % (OUT, len(rows)))


if __name__ == '__main__':
    main()
