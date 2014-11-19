require_relative 'simctl'
require 'RSpec'

# yeah, could use a lot more tests

RSpec.describe "SimCtl Module" do
	unique_name = "UnitTest.Device.SimCtl"

	it 'does not have a device with this name' do
		expect(SimCtl.find_unique_device(unique_name)).to eq nil
	end

	it 'creates a device' do
		d = SimCtl.create(unique_name,'iPhone 6','iOS 8.1')
		puts d
		expect(d).not_to be_nil
		created = !d.nil?
	end

	it 'has a device with this name' do
		d = SimCtl.find_unique_device(unique_name)
		expect(d).not_to be_nil
		expect(d.name).to eq unique_name
	end

	it 'deletes' do
		d = SimCtl.find_unique_device(unique_name)
		d.delete
		expect(SimCtl.find_unique_device(unique_name)).to eq nil
	end
end