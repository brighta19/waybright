part of './waybright.dart';

enum InputDeviceButton {
  unknown1, // 0
  escape, // 1
  digit1, // 2
  digit2, // 3
  digit3, // 4
  digit4, // 5
  digit5, // 6
  digit6, // 7
  digit7, // 8
  digit8, // 9
  digit9, // 10
  digit0, // 11
  minus, // 12
  equal, // 13
  backspace, // 14
  tab, // 15
  keyQ, // 16
  keyW, // 17
  keyE, // 18
  keyR, // 19
  keyT, // 20
  keyY, // 21
  keyU, // 22
  keyI, // 23
  keyO, // 24
  keyP, // 25
  bracketLeft, // 26
  bracketRight, // 27
  enter, // 28
  controlLeft, // 29
  keyA, // 30
  keyS, // 31
  keyD, // 32
  keyF, // 33
  keyG, // 34
  keyH, // 35
  keyJ, // 36
  keyK, // 37
  keyL, // 38
  semicolon, // 39
  quote, // 40
  backquote, // 41
  shiftLeft, // 42
  backslash, // 43
  keyZ, // 44
  keyX, // 45
  keyC, // 46
  keyV, // 47
  keyB, // 48
  keyN, // 49
  keyM, // 50
  comma, // 51
  period, // 52
  slash, // 53
  shiftRight, // 54
  numpadMultiply, // 55
  altLeft, // 56
  space, // 57
  capsLock, // 58
  f1, // 59
  f2, // 60
  f3, // 61
  f4, // 62
  f5, // 63
  f6, // 64
  f7, // 65
  f8, // 66
  f9, // 67
  f10, // 68
  unknown2, // 69
  scrollLock, // 70
  numpad7, // 71
  numpad8, // 72
  numpad9, // 73
  numpadSubtract, // 74
  numpad4, // 75
  numpad5, // 76
  numpad6, // 77
  numpadAdd, // 78
  numpad1, // 79
  numpad2, // 80
  numpad3, // 81
  numpad0, // 82
  numpadDecimal, // 83
  unknown3, // 84
  unknown4, // 85
  unknown5, // 86
  f11, // 87
  f12, // 88
  unknown6, // 89
  unknown7, // 90
  unknown8, // 91
  unknown9, // 92
  unknown10, // 93
  unknown11, // 94
  unknown12, // 95
  numpadEnter, // 96
  controlRight, // 97
  numpadDivide, // 98
  printScreen, // 99
  altRight, // 100
  unknown13, // 101
  home, // 102
  arrowUp, // 103
  pageUp, // 104
  arrowLeft, // 105
  arrowRight, // 106
  end, // 107
  arrowDown, // 108
  pageDown, // 109
  insert, // 110
  delete, // 111
  unknown14, // 112
  volumeMute, // 113
  volumeDown, // 114
  volumeUp, // 115
  unknown15,
  unknown16, // 117
  unknown17, // 118
  pause, // 119
  numpadEqual, // 120
  numpadComma, // 121
  unknown18, // 122
  unknown19, // 123
  unknown20, // 124
  metaLeft, // 125
  metaRight, // 126
  contextMenu, // 127
  webStop, // 128
  numpadParenLeft, // 129
  numpadParenRight, // 130
  unknown21, // 131
  unknown22, // 132
  unknown23, // 133
  unknown24, // 134
  unknown25, // 135
  unknown26, // 136
  unknown27, // 137
  unknown28, // 138
  unknown29, // 139
  startCalculator, // 140
  unknown30, // 141
  unknown31, // 142
  unknown32, // 143
  unknown33, // 144
  unknown34, // 145
  unknown35, // 146
  unknown36, // 147
  unknown37, // 148
  unknown38, // 149
  unknown39, // 150
  unknown40, // 151
  unknown41, // 152
  unknown42, // 153
  unknown43, // 154
  startEmail, // 155
  unknown44, // 156
  showMyFiles, // 157
  webBack, // 158
  webForward, // 159
  unknown45, // 160
  unknown46, // 161
  unknown47, // 162
  mediaForward, // 163
  mediaPlayPause, // 164
  mediaBack, // 165
  mediaStop, // 166
  unknown48, // 167
  unknown49, // 168
  unknown50, // 169
  unknown51, // 170
  unknown52, // 171
  webHome, // 172
  webRefresh, // 173
  unknown53, // 174
  unknown54, // 175
  unknown55, // 176
  unknown56, // 177
  unknown57, // 178
  unknown58, // 179
  unknown59, // 180
  unknown60, // 181
  unknown61, // 182
  unknown62, // 183
  unknown63, // 184
  unknown64, // 185
  unknown65, // 186
  unknown66, // 187
  unknown67, // 188
  unknown68, // 189
  unknown69, // 190
  unknown70, // 191
  unknown71, // 192
  unknown72, // 193
  unknown73, // 194
  unknown74, // 195
  unknown75, // 196
  unknown76, // 197
  unknown77, // 198
  unknown78, // 199
  unknown79, // 200
  unknown80, // 201
  unknown81, // 202
  unknown82, // 203
  unknown83, // 204
  unknown84, // 205
  unknown85, // 206
  unknown86, // 207
  unknown87, // 208
  unknown88, // 209
  unknown89, // 210
  unknown90, // 211
  unknown91, // 212
  unknown92, // 213
  unknown93, // 214
  unknown94, // 215
  unknown95, // 216
  webSearch, // 217
  unknown96, // 218
  unknown97, // 219
  unknown98, // 220
  unknown99, // 221
  unknown100, // 222
  unknown101, // 223
  unknown102, // 224
  unknown103, // 225
  showMediaFiles, // 226
  unknown104, // 227
  unknown105, // 228
  unknown106, // 229
  unknown107, // 230
  unknown108, // 231
  unknown109, // 232
  unknown110, // 233
  unknown111, // 234
  unknown112, // 235
  unknown113, // 236
  unknown114, // 237
  unknown115, // 238
  unknown116, // 239
  unknown117, // 240
  unknown118, // 241
  unknown119, // 242
  unknown120, // 243
  unknown121, // 244
  unknown122, // 245
  unknown123, // 246
  unknown124, // 247
  unknown125, // 248
  unknown126, // 249
  unknown127, // 250
  unknown128, // 251
  unknown129, // 252
  unknown130, // 253
  unknown131, // 254
  unknown132, // 255
  unknown133, // 256
  unknown134, // 257
  unknown135, // 258
  unknown136, // 259
  unknown137, // 260
  unknown138, // 261
  unknown139, // 262
  unknown140, // 263
  unknown141, // 264
  unknown142, // 265
  unknown143, // 266
  unknown144, // 267
  unknown145, // 268
  unknown146, // 269
  unknown147, // 270
  unknown148, // 271
  mouseLeft, // 272
  mouseRight, // 273
  mouseMiddle, // 274
  mouseBack, // 275
  mouseForward, // 276
}

enum InputDeviceType {
  pointer,
  keyboard,
}

/// An input device
class InputDevice {
  InputDeviceType type;

  InputDevice(this.type);
}
