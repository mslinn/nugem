require 'rspec/match_ignoring_whitespace'

require_relative 'spec_helper'
require_relative '../lib/nugem/scaffold/jekyll_demo'

class JekyllTagTest
  RSpec.describe ::Nugem::JekyllDemo do
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

      actual = described_class.add 'my_tag', params, :tag
      # puts actual.yellow
      expected = <<~END_EX
        <h2 id="tag_my_tag" class='code'>my_tag</h2>
        <!-- #region my_tag  (invoked without parameters) -->
        <h3 id="my_tag" class="code">my_tag  (invoked without parameters)</h3>
        {% my_tag  %}
        <!-- endregion -->

        <!-- #region my_tag option1='somevalue' -->
        <h3 id="my_tag" class="code">my_tag option1='somevalue'</h3>
        {% my_tag option1='somevalue' %}
        <!-- endregion -->

        <!-- #region my_tag option2 -->
        <h3 id="my_tag" class="code">my_tag option2</h3>
        {% my_tag option2 %}
        <!-- endregion -->

        <!-- #region my_tag option3=1234 -->
        <h3 id="my_tag" class="code">my_tag option3=1234</h3>
        {% my_tag option3=1234 %}
        <!-- endregion -->

        <!-- #region my_tag option1='somevalue' option2 -->
        <h3 id="my_tag" class="code">my_tag option1='somevalue' option2</h3>
        {% my_tag option1='somevalue' option2 %}
        <!-- endregion -->

        <!-- #region my_tag option1='somevalue' option3=1234 -->
        <h3 id="my_tag" class="code">my_tag option1='somevalue' option3=1234</h3>
        {% my_tag option1='somevalue' option3=1234 %}
        <!-- endregion -->

        <!-- #region my_tag option2 option3=1234 -->
        <h3 id="my_tag" class="code">my_tag option2 option3=1234</h3>
        {% my_tag option2 option3=1234 %}
        <!-- endregion -->

        <!-- #region my_tag option1='somevalue' option2 option3=1234 -->
        <h3 id="my_tag" class="code">my_tag option1='somevalue' option2 option3=1234</h3>
        {% my_tag option1='somevalue' option2 option3=1234 %}
        <!-- endregion -->
      END_EX
      expect(actual).to match_ignoring_whitespace(expected)
    end
  end
end
