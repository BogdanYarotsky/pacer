import Toybox.Lang;
import Toybox.Test;

(:test)
function editorLayoutMapsEveryControl(logger as Test.Logger) as Boolean {
    var w = 390;
    Test.assertEqualMessage(Layout.editorActionAt(55, 130, w), Layout.ACTION_PACE_DOWN, "pace -");
    Test.assertEqualMessage(Layout.editorActionAt(335, 130, w), Layout.ACTION_PACE_UP, "pace +");
    Test.assertEqualMessage(Layout.editorActionAt(55, 202, w), Layout.ACTION_STRENGTH_DOWN, "strength -");
    Test.assertEqualMessage(Layout.editorActionAt(335, 202, w), Layout.ACTION_STRENGTH_UP, "strength +");
    Test.assertEqualMessage(Layout.editorActionAt(55, 274, w), Layout.ACTION_DURATION_DOWN, "duration -");
    Test.assertEqualMessage(Layout.editorActionAt(335, 274, w), Layout.ACTION_DURATION_UP, "duration +");
    return true;
}

(:test)
function editorLayoutRejectsLabelsAndOutsideRows(logger as Test.Logger) as Boolean {
    var w = 390;
    Test.assertEqualMessage(Layout.editorActionAt(195, 130, w), Layout.ACTION_NONE, "pace label");
    Test.assertEqualMessage(Layout.editorActionAt(55, 90, w), Layout.ACTION_NONE, "above rows");
    Test.assertEqualMessage(Layout.editorActionAt(335, 312, w), Layout.ACTION_NONE, "below rows");
    return true;
}
