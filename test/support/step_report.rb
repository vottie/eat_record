# ブラウザテストの、ステップごとの結果(成功・失敗・警告、時間)を記録し、表にして出す。
# 標準出力に出し、GITHUB_STEP_SUMMARY があれば(GitHub Actions)、ジョブサマリにも書く。
module StepReport
  Step = Struct.new(:screen, :id, :name, :result, :seconds, :message, keyword_init: true)

  @steps = []

  class << self
    attr_reader :steps

    def record(**attrs)
      @steps << Step.new(**attrs)
    end

    def markdown
      failed = @steps.count { |s| s.result == "Failed" }
      warned = @steps.count { |s| s.result == "Warning" }
      lines = []
      lines << "## Staging check"
      lines << ""
      lines << "Passed #{@steps.count { |s| s.result == 'Passed' }} / Failed #{failed} / Warning #{warned} (#{@steps.size} steps in total)"
      lines << ""
      lines << "| Screen | Step | Result | Time | Details |"
      lines << "|---|---|---|---|---|"
      @steps.each do |s|
        lines << "| #{s.screen} | #{s.id} #{s.name} | #{s.result} | #{format('%.1f', s.seconds)} s | #{cell(s.message)} |"
      end
      lines.join("\n") + "\n"
    end

    def write
      return if @steps.empty?
      puts "\n" + markdown
      path = ENV["GITHUB_STEP_SUMMARY"]
      File.open(path, "a") { |f| f.write(markdown) } if path.to_s != ""
    end

    private

    # 表の 1 セルに収める(改行・縦線を除き、長ければ切る)。公開ログに出るため、短くする。
    def cell(message)
      message.to_s.gsub(/\s+/, " ").delete("|")[0, 160]
    end
  end
end

Minitest.after_run { StepReport.write }
