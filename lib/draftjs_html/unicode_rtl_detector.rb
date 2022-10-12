module DraftjsHtml
  class UnicodeRtlDetector
    # This regex was copied from fbjs's UnicodeBidi detection
    # See https://github.com/facebook/fbjs/blob/main/packages/fbjs/src/unicode/UnicodeBidi.js.
    STRONG_RTL_CHAR_RANGES = [
      '\u0590\u05BE\u05C0\u05C3\u05C6\u05C8-\u05CF\u05D0-\u05EA\u05EB-\u05EF',
      '\u05F0-\u05F2\u05F3-\u05F4\u05F5-\u05FF\u07C0-\u07C9\u07CA-\u07EA',
      '\u07F4-\u07F5\u07FA\u07FB-\u07FF\u0800-\u0815\u081A\u0824\u0828',
      '\u082E-\u082F\u0830-\u083E\u083F\u0840-\u0858\u085C-\u085D\u085E',
      '\u085F-\u089F\u200F\uFB1D\uFB1F-\uFB28\uFB2A-\uFB36\uFB37\uFB38-\uFB3C',
      '\uFB3D\uFB3E\uFB3F\uFB40-\uFB41\uFB42\uFB43-\uFB44\uFB45\uFB46-\uFB4F',
      '\u0608\u060B\u060D\u061B\u061C\u061D\u061E-\u061F\u0620-\u063F\u0640',
      '\u0641-\u064A\u066D\u066E-\u066F\u0671-\u06D3\u06D4\u06D5\u06E5-\u06E6',
      '\u06EE-\u06EF\u06FA-\u06FC\u06FD-\u06FE\u06FF\u0700-\u070D\u070E\u070F',
      '\u0710\u0712-\u072F\u074B-\u074C\u074D-\u07A5\u07B1\u07B2-\u07BF',
      '\u08A0-\u08B2\u08B3-\u08E3\uFB50-\uFBB1\uFBB2-\uFBC1\uFBC2-\uFBD2',
      '\uFBD3-\uFD3D\uFD40-\uFD4F\uFD50-\uFD8F\uFD90-\uFD91\uFD92-\uFDC7',
      '\uFDC8-\uFDCF\uFDF0-\uFDFB\uFDFC\uFDFE-\uFDFF\uFE70-\uFE74\uFE75',
      '\uFE76-\uFEFC\uFEFD-\uFEFE',
    ].join.freeze
    RTL_MATCHER = /[#{STRONG_RTL_CHAR_RANGES}]/

    def contains_rtl?(text)
      RTL_MATCHER.match?(text)
    end
  end
end