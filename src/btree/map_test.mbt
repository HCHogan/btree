///|
test "btree" {
    let data = [
    (50, "fifty"), (30, "thirty"), (70, "seventy"), (20, "twenty"),
    (40, "forty"), (60, "sixty"), (80, "eighty"), (10, "ten"),
    (25, "twenty-five"), (35, "thirty-five"), (45, "forty-five"),
    (55, "fifty-five"), (65, "sixty-five"), (75, "seventy-five"),
    (90, "ninety"), (5, "five"), (15, "fifteen"), (28, "twenty-eight"),
    (38, "thirty-eight"), (48, "forty-eight"), (58, "fifty-eight"),
    (68, "sixty-eight"), (78, "seventy-eight"), (85, "eighty-five"),
    (95, "ninety-five"), (100, "one hundred")
  ]
  let tree = from_array(data)
  println(tree.to_string_pretty())
  inspect(tree.size(),
    content="\{data.length()}"
  )
}
