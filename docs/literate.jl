using Literate
using CairoMakie

CairoMakie.activate!(type = "png")

script_path = ARGS[1]
literated_dir = ARGS[2]

# Only execute examples if CDS credentials are available (set EXECUTE_EXAMPLES=true to force)
# By default, skip execution since examples require ERA5 downloads
execute_examples = get(ENV, "EXECUTE_EXAMPLES", "false") == "true"

@time basename(script_path) Literate.markdown(script_path, literated_dir;
                                              flavor = Literate.DocumenterFlavor(),
                                              execute = execute_examples)

