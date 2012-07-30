
# Taken from: https://github.com/loopj/commonjs-ansi-color
module.exports = (str, color) ->
  ANSI_CODES =
    off: 0
    bold: 1
    italic: 3
    underline: 4
    blink: 5
    inverse: 7
    hidden: 8
    black: 30
    red: 31
    green: 32
    yellow: 33
    blue: 34
    magenta: 35
    cyan: 36
    white: 37
    black_bg: 40
    red_bg: 41
    green_bg: 42
    yellow_bg: 43
    blue_bg: 44
    magenta_bg: 45
    cyan_bg: 46
    white_bg: 47

  return str unless color

  colorAttributes = color.split("+")
  ansiString = ""

  for attr, i in colorAttributes
    ansiString += "\u001b[" + ANSI_CODES[attr] + "m"

  ansiString += str + "\u001b[" + ANSI_CODES["off"] + "m"
  ansiString