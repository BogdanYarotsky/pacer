import Toybox.Lang;

// What each screen carries, in the order it carries it. ADR-0028
module Rows {

    // Identities, NOT positions. A row's position is its index in the list
    // forScreen returns, and nothing outside that list may assume one. ADR-0014
    const EVERY = 0;
    const BUZZ = 1;
    const POWER = 2;

    // PACE is EVERY in the other unit -- one setting, two rows. ADR-0019
    const PACE = 3;

    const SCREEN_MAIN = 0;
    const SCREEN_SETTINGS = 1;

    // The only place row order is decided. Swapping two names here moves the
    // rows on the glass and moves every tap with them, in the same edit.
    // ADR-0028
    function forScreen(screen as Number) as Array<Number> {
        if (screen == SCREEN_SETTINGS) {
            return [EVERY, PACE] as Array<Number>;
        }
        return [POWER, BUZZ] as Array<Number>;
    }
}
