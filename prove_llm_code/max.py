from z3 import Int, If, Or, And, Solver, sat, unsat

# Symbolic inputs
a = Int("a")
b = Int("b")

# Symbolic return value
r = Int("r")

s = Solver()

# Encode:
# int max2(int a, int b) {
#     if (a >= b) return a;
#     else return b;
# }
s.add(r == If(a >= b, a, b))

# Ask for a counterexample:
# max2 is wrong if:
# 1) r < a, or
# 2) r < b, or
# 3) r is neither a nor b
bug = Or(
    r < a,
    r < b,
    And(r != a, r != b)
)

s.add(bug)

result = s.check()
print("Solver result:", result)

if result == sat:
    print("Counterexample found:")
    print(s.model())
elif result == unsat:
    print("No counterexample exists. max2 satisfies the spec.")
else:
    print("Solver returned unknown.")