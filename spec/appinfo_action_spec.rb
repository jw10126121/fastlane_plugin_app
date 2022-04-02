describe Fastlane::Actions::AppinfoAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The appinfo plugin is working!")

      Fastlane::Actions::AppinfoAction.run(nil)
    end
  end
end
