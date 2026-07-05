using Test
using QuickCharts

w1, h1 = QuickCharts.getsize("Axial \$sigma_n\$", 8.0)
w2, h2 = QuickCharts.getsize("Axial `sigma_n`", 8.0)
@test isapprox(w1, w2; atol=1.0e-6)
@test isapprox(h1, h2; atol=1.0e-6)

wm, hm = QuickCharts.getsize("Load `P` at \$x\$", 8.0)
@test wm > 0
@test hm > 0

plain_nodes = QuickCharts.parse_typeset("Isoparametric quadratic beam")
@test length(plain_nodes) == 1
@test plain_nodes[1].text == "Isoparametric quadratic beam"
@test !plain_nodes[1].italic

escaped_tick_nodes = QuickCharts.parse_typeset("label \\` tick")
@test [n.text for n in escaped_tick_nodes] == ["label ", "`", " tick"]

math_nodes = QuickCharts.parse_typeset("`xAh`")
@test [n.text for n in math_nodes] == ["x", "A", "h"]
@test all(n.italic for n in math_nodes)

greek_nodes = QuickCharts.parse_typeset("`alpha Gamma varepsilon times partial`")
@test [n.text for n in greek_nodes] == ["α", "Γ", "ε", "×", "∂"]
@test [n.italic for n in greek_nodes] == [true, true, true, false, false]

number_nodes = QuickCharts.parse_typeset("`0.5`")
@test length(number_nodes) == 1
@test number_nodes[1].text == "0.5"
@test !number_nodes[1].italic

integer_nodes = QuickCharts.parse_typeset("`12`")
@test length(integer_nodes) == 1
@test integer_nodes[1].text == "12"

leading_decimal_nodes = QuickCharts.parse_typeset("`.5`")
@test length(leading_decimal_nodes) == 1
@test leading_decimal_nodes[1].text == ".5"

trailing_decimal_nodes = QuickCharts.parse_typeset("`5.`")
@test length(trailing_decimal_nodes) == 1
@test trailing_decimal_nodes[1].text == "5."

scientific_nodes = QuickCharts.parse_typeset("`1e-3`")
@test length(scientific_nodes) == 1
@test scientific_nodes[1].text == "1e-3"

scientific_upper_nodes = QuickCharts.parse_typeset("`2.0E5`")
@test length(scientific_upper_nodes) == 1
@test scientific_upper_nodes[1].text == "2.0E5"

signed_number_nodes = QuickCharts.parse_typeset("`-0.5`")
@test length(signed_number_nodes) == 2
@test [n.text for n in signed_number_nodes] == ["−", "0.5"]

num_fun_nodes = QuickCharts.parse_typeset("`0.5sin(x)`")
@test length(num_fun_nodes) == 3
@test num_fun_nodes[1].text == "0.5"
@test num_fun_nodes[2].text == "sin"
@test num_fun_nodes[3] isa QuickCharts.TSParenGroup

num_fun_spaced_nodes = QuickCharts.parse_typeset("`0.5 sin(x)`")
@test length(num_fun_spaced_nodes) == 3
@test num_fun_spaced_nodes[1].text == "0.5"
@test num_fun_spaced_nodes[2].text == "sin"

num_var_nodes = QuickCharts.parse_typeset("`2x`")
@test length(num_var_nodes) == 2
@test [n.text for n in num_var_nodes] == ["2", "x"]

num_identifier_nodes = QuickCharts.parse_typeset("`2foo`")
@test [n.text for n in num_identifier_nodes] == ["2", "f", "o", "o"]

@test isapprox(QuickCharts._implicit_atom_spacing(num_fun_nodes[1], num_fun_nodes[2], 10.0), 0.8)
@test QuickCharts._implicit_atom_spacing(num_var_nodes[1], num_var_nodes[2], 10.0) == 0.0
@test QuickCharts._implicit_atom_spacing(num_identifier_nodes[1], num_identifier_nodes[2], 10.0) == 0.0
@test QuickCharts._implicit_atom_spacing(signed_number_nodes[1], signed_number_nodes[2], 10.0) == 0.0

quoted_text_nodes = QuickCharts.parse_typeset("`x_\"min\"`")
@test length(quoted_text_nodes) == 1
@test quoted_text_nodes[1] isa QuickCharts.TSScripts
sub = quoted_text_nodes[1].sub
@test sub isa QuickCharts.TSAtom
@test sub.text == "min"
@test !sub.italic

mixed_quoted_nodes = QuickCharts.parse_typeset("`alpha + \"text\"`")
@test mixed_quoted_nodes[end] isa QuickCharts.TSAtom
@test mixed_quoted_nodes[end].text == "text"
@test !mixed_quoted_nodes[end].italic

double_quoted_after_base_nodes = QuickCharts.parse_typeset("`x\"tag\"`")
@test length(double_quoted_after_base_nodes) == 2
@test double_quoted_after_base_nodes[2].text == "tag"
@test !double_quoted_after_base_nodes[2].italic

frac_nodes = QuickCharts.parse_typeset("`frac(a,b)`")
@test length(frac_nodes) == 1
@test frac_nodes[1] isa QuickCharts.TSFraction
@test frac_nodes[1].num isa QuickCharts.TSAtom
@test frac_nodes[1].den isa QuickCharts.TSAtom
@test frac_nodes[1].num.text == "a"
@test frac_nodes[1].den.text == "b"

sqrt_nodes = QuickCharts.parse_typeset("`sqrt(x)`")
@test length(sqrt_nodes) == 1
@test sqrt_nodes[1] isa QuickCharts.TSSqrt
@test sqrt_nodes[1].body isa QuickCharts.TSAtom
@test sqrt_nodes[1].body.text == "x"

bold_nodes = QuickCharts.parse_typeset("`bold(x)`")
@test length(bold_nodes) == 1
@test bold_nodes[1] isa QuickCharts.TSAtom
@test bold_nodes[1].text == "x"
@test bold_nodes[1].bold

macron_nodes = QuickCharts.parse_typeset("`macron(x)`")
@test length(macron_nodes) == 1
@test macron_nodes[1] isa QuickCharts.TSOverbar
@test macron_nodes[1].body isa QuickCharts.TSAtom
@test macron_nodes[1].body.text == "x"

prime_nodes = QuickCharts.parse_typeset("`f'`")
@test length(prime_nodes) == 1
@test prime_nodes[1] isa QuickCharts.TSScripts
@test prime_nodes[1].sup isa QuickCharts.TSAtom
@test prime_nodes[1].sup.text == "′"

double_prime_nodes = QuickCharts.parse_typeset("`x''`")
@test length(double_prime_nodes) == 1
@test double_prime_nodes[1] isa QuickCharts.TSScripts
inner = double_prime_nodes[1].base
@test inner isa QuickCharts.TSScripts
@test inner.sup.text == "′"

sub_single_quote_nodes = QuickCharts.parse_typeset("`x_'min'`")
@test length(sub_single_quote_nodes) == 1
@test sub_single_quote_nodes[1] isa QuickCharts.TSScripts
@test sub_single_quote_nodes[1].sub.text == "min"
@test !sub_single_quote_nodes[1].sub.italic

inline_text_nodes = QuickCharts.parse_typeset("`E = 200 'GPa'`")
@test inline_text_nodes[end] isa QuickCharts.TSAtom
@test inline_text_nodes[end].text == "GPa"
@test !inline_text_nodes[end].italic

chart = Chart(
    title="Axial `sigma_n`",
    xlabel="`x`",
    ylabel="`u_x`",
)
add_line(chart, [0.0, 1.0], [0.0, 1.0]; label="`u_x`")
add_annotation(chart, "Load `P` at \$x\$", [0.2, 0.2])
outfile = joinpath("output", "typesetting-backtick.pdf")
save(chart, outfile)
@test isfile(outfile)
