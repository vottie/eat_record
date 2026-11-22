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
      lines << "## Test coverage"
      lines << ""
      lines << "| Type | Coverage | Covered / Total |"
      lines << "|---|---|---|"
      lines << row("Line", result.coverage_statistics[:line])
      lines << row("Branch", result.coverage_statistics[:branch])
      lines << ""
      lines << "<details><summary>Per file (lowest line coverage first)</summary>"
      lines << ""
      lines << "| File | Line | Branch |"
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
      "#{'%.1f' % stat.percent}% (#{stat.covered}/#{stat.total})"
    end

    def relative(filename)
      filename.sub(%r{\A#{Regexp.escape(SimpleCov.root)}/}, "")
    end
  end
end
