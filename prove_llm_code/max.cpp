#include <iostream>
#include <z3++.h>

int main() {
    z3::context c;
    z3::solver s(c);

    z3::expr a = c.int_const("a");
    z3::expr b = c.int_const("b");
    z3::expr r = c.int_const("r");

    s.add(r == z3::ite(a >= b, a, b));

    z3::expr bug = (r < a) || (r < b) || ((r != a) && (r != b));
    s.add(bug);

    z3::check_result result = s.check();

    std::cout << "Solver result: " << result << "\n";

    if (result == z3::sat) {
        std::cout << "Counterexample found:\n" << s.get_model() << "\n";
    } else if (result == z3::unsat) {
        std::cout << "No counterexample exists. max satisfies the spec.\n";
    } else {
        std::cout << "Solver returned unknown.\n";
    }

    return 0;
}