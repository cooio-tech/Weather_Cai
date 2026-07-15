package com.weather.service;

import net.sourceforge.pinyin4j.PinyinHelper;
import net.sourceforge.pinyin4j.format.HanyuPinyinCaseType;
import net.sourceforge.pinyin4j.format.HanyuPinyinOutputFormat;
import net.sourceforge.pinyin4j.format.HanyuPinyinToneType;
import net.sourceforge.pinyin4j.format.HanyuPinyinVCharType;
import net.sourceforge.pinyin4j.format.exception.BadHanyuPinyinOutputFormatCombination;

final class ChinesePinyin {

    private static final HanyuPinyinOutputFormat FORMAT = new HanyuPinyinOutputFormat();

    static {
        FORMAT.setCaseType(HanyuPinyinCaseType.LOWERCASE);
        FORMAT.setToneType(HanyuPinyinToneType.WITHOUT_TONE);
        FORMAT.setVCharType(HanyuPinyinVCharType.WITH_V);
    }

    private ChinesePinyin() {
    }

    /** Compact pinyin without spaces/apostrophes, e.g. 西安 -> xian, 重庆 -> chongqing */
    static String toCompact(String text) {
        String spaced = toSpaced(text);
        if (spaced == null || spaced.isBlank()) {
            return null;
        }
        return spaced.replace(" ", "").replace("'", "");
    }

    /** Spaced pinyin, e.g. 呼和浩特 -> hu he hao te */
    static String toSpaced(String text) {
        if (text == null || text.isBlank()) {
            return null;
        }
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < text.length(); i++) {
            char ch = text.charAt(i);
            if (Character.isWhitespace(ch)) {
                continue;
            }
            if (ch >= 0x4E00 && ch <= 0x9FFF) {
                try {
                    String[] arr = PinyinHelper.toHanyuPinyinStringArray(ch, FORMAT);
                    if (arr != null && arr.length > 0 && arr[0] != null && !arr[0].isBlank()) {
                        if (sb.length() > 0) {
                            sb.append(' ');
                        }
                        sb.append(arr[0]);
                    }
                } catch (BadHanyuPinyinOutputFormatCombination ignored) {
                    // skip unreadable chars
                }
            } else if (Character.isLetterOrDigit(ch)) {
                if (sb.length() > 0 && sb.charAt(sb.length() - 1) != ' ') {
                    sb.append(' ');
                }
                sb.append(Character.toLowerCase(ch));
            }
        }
        String out = sb.toString().trim();
        return out.isEmpty() ? null : out;
    }
}