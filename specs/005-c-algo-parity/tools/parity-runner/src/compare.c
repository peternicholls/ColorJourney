#include <math.h>
#include <stdlib.h>
#include "cJSON.h"
#include "types.h"

int comparison_within_tolerance(const ComparisonDelta *delta, const ToleranceConfig *tolerance) {
    if (!delta || !tolerance) {
        return 0;
    }

    const double abs_l = fabs(delta->l);
    const double abs_a = fabs(delta->a);
    const double abs_b = fabs(delta->b);
    const double abs_de = fabs(delta->deltaE);

    if (abs_l > tolerance->abs.l && tolerance->abs.l > 0) {
        return 0;
    }
    if (abs_a > tolerance->abs.a && tolerance->abs.a > 0) {
        return 0;
    }
    if (abs_b > tolerance->abs.b && tolerance->abs.b > 0) {
        return 0;
    }
    if (tolerance->abs.deltaE > 0 && abs_de > tolerance->abs.deltaE) {
        return 0;
    }

    if (tolerance->rel.l > 0 && abs_l > tolerance->rel.l * fabs(tolerance->abs.l + 1.0)) {
        return 0;
    }
    if (tolerance->rel.a > 0 && abs_a > tolerance->rel.a * fabs(tolerance->abs.a + 1.0)) {
        return 0;
    }
    if (tolerance->rel.b > 0 && abs_b > tolerance->rel.b * fabs(tolerance->abs.b + 1.0)) {
        return 0;
    }

    return 1;
}

double delta_e_oklab(const OklabColor *a, const OklabColor *b) {
    if (!a || !b) {
        return 0.0;
    }
    const double dl = a->l - b->l;
    const double da = a->a - b->a;
    const double db = a->b - b->b;
    return sqrt((dl * dl) + (da * da) + (db * db));
}
