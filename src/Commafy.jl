# SPDX-License-Identifier: MIT

module Commafy

export commafy

"""
    commafy(n::Integer)

### Arguments
- `n::Integer`: An integer to format with commas as thousands separators.

### Returns
- A string representation of `n` with commas inserted every three digits.
"""
function commafy(n::Integer)
    s = reverse(string(abs(n)))
    parts = [s[i:min(i+2, end)] for i in 1:3:length(s)]
    result = reverse(join(parts, ","))
    n < 0 ? "-$result" : result
end

end # module Commafy
