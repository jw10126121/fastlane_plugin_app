describe Fastlane::Actions::AppAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The app plugin is working!")

      Fastlane::Actions::AppAction.run(nil)
    end
  end
end
