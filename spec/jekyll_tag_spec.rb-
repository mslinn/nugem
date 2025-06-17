require_relative 'spec_helper'

class JekyllTagTest
  RSpec.describe ::Nugem::Cli do
    it 'tests tag option combinations' do
      params = [
        %w[option1 string],
        %w[option2 boolean],
        %w[option3 numeric],
      ]
      expect(params.combination(0).to_a).to eq [[]]
      expect(params.combination(1).to_a).to eq [
        [%w[option1 string]],
        [%w[option2 boolean]],
        [%w[option3 numeric]],
      ]
      expect(params.combination(2).to_a).to eq [
        [%w[option1 string],  %w[option2 boolean]],
        [%w[option1 string],  %w[option3 numeric]],
        [%w[option2 boolean], %w[option3 numeric]],
      ]
      expect(params.combination(3).to_a).to eq [
        [%w[option1 string], %w[option2 boolean], %w[option3 numeric]],
      ]

      actual = described_class.combinations params
      expected = [
        [],
        ["option1='somevalue'"], ['option2'], ['option3=1234'],
        ["option1='somevalue'", 'option2'],
        ["option1='somevalue'", 'option3=1234'],
        ['option2', 'option3=1234'],
        ["option1='somevalue'", 'option2', 'option3=1234']
      ]
      expect(actual).to eq(expected)

      actual = described_class.add_demo_example 'my_tag', params, :tag
      expected = <<~END_EX
        <!-- #region my_tag  -->
        <h2 id="my_tag">my_tag </h2>
        {% my_tag  %}
        <!-- endregion -->


        <!-- #region my_tag option1='somevalue' -->
        <h2 id="my_tag">my_tag option1='somevalue'</h2>
        {% my_tag option1='somevalue' %}
        <!-- endregion -->


        <!-- #region my_tag option2 -->
        <h2 id="my_tag">my_tag option2</h2>
        {% my_tag option2 %}
        <!-- endregion -->


        <!-- #region my_tag option3=1234 -->
        <h2 id="my_tag">my_tag option3=1234</h2>
        {% my_tag option3=1234 %}
        <!-- endregion -->


        <!-- #region my_tag option1='somevalue' option2 -->
        <h2 id="my_tag">my_tag option1='somevalue' option2</h2>
        {% my_tag option1='somevalue' option2 %}
        <!-- endregion -->


        <!-- #region my_tag option1='somevalue' option3=1234 -->
        <h2 id="my_tag">my_tag option1='somevalue' option3=1234</h2>
        {% my_tag option1='somevalue' option3=1234 %}
        <!-- endregion -->


        <!-- #region my_tag option2 option3=1234 -->
        <h2 id="my_tag">my_tag option2 option3=1234</h2>
        {% my_tag option2 option3=1234 %}
        <!-- endregion -->


        <!-- #region my_tag option1='somevalue' option2 option3=1234 -->
        <h2 id="my_tag">my_tag option1='somevalue' option2 option3=1234</h2>
        {% my_tag option1='somevalue' option2 option3=1234 %}
        <!-- endregion -->
      END_EX
      expect(actual).to eq(expected)
    end
  end
end
