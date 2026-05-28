# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'
require 'operations/operation_event_support'

RSpec.describe Moose::Inventory::Operations::OperationEventSupport do
  subject(:operation) { operation_class.new }

  let(:operation_class) do
    Class.new do
      include Moose::Inventory::Operations::OperationEventSupport

      def event(type, payload = {})
        build_event(type, payload)
      end

      def append_event(events, type, payload = {})
        emit(events, type, payload)
      end

      def result(events:, warning_count: 0)
        operation_result(events: events, warning_count: warning_count)
      end
    end
  end

  describe '#build_event' do
    it 'builds structured events with an empty default payload' do
      event = operation.event(:started)

      expect(event).to be_a(described_class::Event)
      expect(event.type).to eq(:started)
      expect(event.payload).to eq({})
    end

    it 'preserves the provided event payload' do
      event = operation.event(:created, name: 'testhost')

      expect(event.type).to eq(:created)
      expect(event.payload).to eq(name: 'testhost')
    end
  end

  describe '#emit' do
    it 'appends a constructed event to the provided collection' do
      events = []

      result = operation.append_event(events, :warning, name: 'missinggroup')
      event = events.fetch(0)

      expect(result).to eq(events)
      expect(event).to be_a(described_class::Event)
      expect(event.type).to eq(:warning)
      expect(event.payload).to eq(name: 'missinggroup')
    end
  end

  describe '#operation_result' do
    it 'defaults warning_count to zero' do
      events = [operation.event(:ok)]

      result = operation.result(events: events)

      expect(result).to be_a(described_class::Result)
      expect(result.events).to eq(events)
      expect(result.warning_count).to eq(0)
      expect(result.warning_count.zero?).to eq(true)
    end

    it 'preserves an explicit warning_count' do
      result = operation.result(events: [], warning_count: 2)

      expect(result.warning_count).to eq(2)
    end
  end
end
# rubocop:enable Metrics/BlockLength
