
class ActionsLogger < Logger
    def initialize
        super(Rails.root.join('log/actions.log'), 'daily')
        self.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime.to_s(:db)} #{severity}: #{msg}\n"
        end
    end
end