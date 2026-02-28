
/* (c)  oblong industries */

/* Test slaw_spew_overview_to_string_ex(). */

#include "libLoam/c/ob-log.h"
#include "libLoam/c/ob-vers.h"
#include "libPlasma/c/slaw.h"

#include <stdlib.h>
#include <string.h>

/* Test that _ex(s, false, NULL) returns the same string as
 * slaw_spew_overview_to_string(s). */
static void test_false_null_matches_non_ex (void)
{
  slaw s = slaw_string ("phosphorescent");
  slaw r1 = slaw_spew_overview_to_string (s);
  slaw r2 = slaw_spew_overview_to_string_ex (s, false, NULL);
  if (!slawx_equal (r1, r2))
    OB_FATAL_ERROR_CODE (0x2031b000,
                         "expected:\n%s\nbut got:\n%s\n",
                         slaw_string_emit (r1),
                         slaw_string_emit (r2));
  slaw_free (r1);
  slaw_free (r2);
  slaw_free (s);
}

/* Test that relative-offset output differs from absolute-pointer
 * output.  Since the top-level slaw's relative offset is always 0,
 * but its absolute address is non-zero, the two strings must differ.
 */
static void test_relative_differs_from_absolute (void)
{
  slaw s = slaw_string ("phosphorescent");
  slaw rel = slaw_spew_overview_to_string_ex (s, true, NULL);
  slaw abs = slaw_spew_overview_to_string_ex (s, false, NULL);
  if (slawx_equal (rel, abs))
    OB_FATAL_ERROR_CODE (
      0x2031b001,
      "relative and absolute outputs should not be equal\n");
  slaw_free (rel);
  slaw_free (abs);
  slaw_free (s);
}

/* Test that the top-level slaw's relative offset is annotated as 0.
 * Use a small string so that num_digits is 1 and no padding is added,
 * making the marker unambiguous. */
static void test_relative_offset_is_zero_for_top_level (void)
{
  slaw s = slaw_string ("abc");
  slaw r = slaw_spew_overview_to_string_ex (s, true, NULL);
  const char *str = slaw_string_emit (r);
  if (!str)
    OB_FATAL_ERROR_CODE (0x2031b002, "got NULL string\n");
  /* The top-level slaw is at relative offset 0, so the annotation
   * must contain "o.0x0]:" with no padding. */
  if (!strstr (str, "o.0x0]: "))
    OB_FATAL_ERROR_CODE (
      0x2031b003,
      "expected 'o.0x0]: ' in relative-offset output: %s\n", str);
  slaw_free (r);
  slaw_free (s);
}

/* Test that the prolo is prepended to the top-level annotation. */
static void test_prolo_on_single_slaw (void)
{
  slaw s = slaw_string ("phosphorescent");
  slaw r = slaw_spew_overview_to_string_ex (s, false, ">>");
  const char *str = slaw_string_emit (r);
  if (!str)
    OB_FATAL_ERROR_CODE (0x2031b004, "got NULL string\n");
  if (strncmp (str, ">>slaw[", 7) != 0)
    OB_FATAL_ERROR_CODE (
      0x2031b005,
      "expected '>>slaw[' at start, got: %s\n", str);
  slaw_free (r);
  slaw_free (s);
}

/* Test that the prolo is prepended to each sub-element line in a
 * multi-element list. */
static void test_prolo_on_list (void)
{
  slaw s =
    slaw_list_inline_f (slaw_string ("alpha"), slaw_string ("beta"),
                        NULL);
  slaw r = slaw_spew_overview_to_string_ex (s, false, "::");
  const char *str = slaw_string_emit (r);
  if (!str)
    OB_FATAL_ERROR_CODE (0x2031b006, "got NULL string\n");
  /* Top-level line starts with "::" */
  if (strncmp (str, "::slaw[", 7) != 0)
    OB_FATAL_ERROR_CODE (
      0x2031b007,
      "expected '::slaw[' at start, got: %s\n", str);
  /* Each sub-element line is prefixed with "::" followed by
   * " N: ".  The newline before the prefix is emitted separately,
   * so we look for "\n:: ". */
  if (!strstr (str, "\n:: "))
    OB_FATAL_ERROR_CODE (
      0x2031b008,
      "expected '\\n:: ' for sub-element lines, got: %s\n", str);
  slaw_free (r);
  slaw_free (s);
}

/* Test that a NULL slaw produces "[no slaw -- NULL]". */
static void test_null_slaw (void)
{
  slaw r = slaw_spew_overview_to_string_ex (NULL, false, NULL);
  const char *str = slaw_string_emit (r);
  if (!str)
    OB_FATAL_ERROR_CODE (0x2031b009, "got NULL string\n");
  const char *expected = "[no slaw -- NULL]";
  if (strcmp (str, expected) != 0)
    OB_FATAL_ERROR_CODE (0x2031b00a,
                         "expected '%s' but got '%s'\n",
                         expected, str);
  slaw_free (r);
}

/* Test that a NULL slaw with a prolo returns the prolo prepended to
 * "[no slaw -- NULL]". */
static void test_null_slaw_with_prolo (void)
{
  slaw r = slaw_spew_overview_to_string_ex (NULL, false, "XX");
  const char *str = slaw_string_emit (r);
  if (!str)
    OB_FATAL_ERROR_CODE (0x2031b00b, "got NULL string\n");
  const char *expected = "XX[no slaw -- NULL]";
  if (strcmp (str, expected) != 0)
    OB_FATAL_ERROR_CODE (0x2031b00c,
                         "expected '%s' but got '%s'\n",
                         expected, str);
  slaw_free (r);
}

int main (int argc, char **argv)
{
  OB_DIE_ON_ERROR (OB_CHECK_ABI ());

  test_false_null_matches_non_ex ();
  test_relative_differs_from_absolute ();
  test_relative_offset_is_zero_for_top_level ();
  test_prolo_on_single_slaw ();
  test_prolo_on_list ();
  test_null_slaw ();
  test_null_slaw_with_prolo ();

  return EXIT_SUCCESS;
}
