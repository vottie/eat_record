# SimpleCov の結果(全体と、ファイルごとの行・分岐のカバレッジ)を、表にして GitHub Actions のジョブサマリに書く(#68)。
# GITHUB_STEP_SUMMARY があるときだけ書く。ローカルでは、SimpleCov 標準の出力(端末と coverage/index.html)だけ。
# 可視化のみで、閾値は設けない。
module CoverageSummary
  class Formatter
    def format(result)
      path = ENV["GITHUB_STEP_SUMMARY"]
      return if path.to_s.empty?

      File.open(path, "a") { |f| f.write(markdown(result)) }
    end

    private

    # 注意: このクラスは format メソッドを定義しているため、文字列の整形には Kernel#format ではなく % を使う

    def markdown(result)
      lines = []
      lines << "## テストカバレッジ"
      lines << ""
      lines << "| 区分 | カバー率 | カバー / 対象 |"
      lines << "|---|---|---|"
      lines << row("行", result.coverage_statistics[:line])
      lines << row("分岐", result.coverage_statistics[:branch])
      lines << ""
      lines << "<details><summary>ファイルごと(行のカバー率が低い順)</summary>"
      lines << ""
      lines << "| ファイル | 行 | 分岐 |"
      lines << "|---|---|---|"
      result.files.sort_by { |f| [f.covered_percent, f.filename] }.each do |file|
        lines << "| `#{relative(file.filename)}` | #{cell(file.coverage_statistics[:line])} | #{cell(file.coverage_statistics[:branch])} |"
      end
      lines << ""
      lines << "</details>"
      lines.join("\n") + "\n"
    end

    def row(label, stat)
      return "| #{label} | - | - |" unless stat
      "| #{label} | #{'%.2f' % stat.percent}% | #{stat.covered} / #{stat.total} |"
    end

    # 対象が 0 件(分岐がないファイルなど)は「-」にする
    def cell(stat)
      return "-" if stat.nil? || stat.total.zero?
      "#{'%.1f' % stat.percent}%(#{stat.covered}/#{stat.total})"
    end

    def relative(filename)
      filename.sub(%r{\A#{Regexp.escape(SimpleCov.root)}/}, "")
    end
  end
end
