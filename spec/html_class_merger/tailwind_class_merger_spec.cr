require "../spec_helper"
require "../../src/html_class_merger/tailwind_class_merger"

class HtmlClassMerger
  TestTailwindMerger = TailwindClassMerger.new
  TestTailwindMerger.register! :bg, /\Abg-/
  TestTailwindMerger.register! :text, [/\Atext-/]
  TestTailwindMerger.register! :border, [/border-\d/, "border-none"], replace: %i(border_x border_y)

  {
    { :border_x, "x", [ { :border_l, "l" }, { :border_r, "r" } ] },
    { :border_y, "y", [ { :border_t, "t" }, { :border_b, "b" } ] },
  }.each do |(group, axis, sides)|
    TestTailwindMerger.register! group, [/border-#{axis}-\d/, "border-#{axis}-none"], replace: sides.map(&.first)
    sides.each do |group, side|
      TestTailwindMerger.register! group, [/border-#{side}-\d/, "border-#{side}-none"]
    end
  end

  describe TailwindClassMerger do
    describe "#merge" do
      it "demonstrates simple group override" do
        TestTailwindMerger.merge("bg-red bg-white text-green text-black").should eq "bg-white text-black"
      end

      it "demonstrates replacing groups" do
        TestTailwindMerger.merge("border-l-1 border-x-2 border-3").should eq "border-3"
        TestTailwindMerger.merge("border-l-1 border-x-2").should eq "border-x-2"
        TestTailwindMerger.merge("border-l-1 border-y-2").should eq "border-l-1 border-y-2"
        TestTailwindMerger.merge("border-3 border-x-2 border-l-1").should eq "border-3 border-x-2 border-l-1"
        TestTailwindMerger.merge("border-l-1 border-y-2 border-l-3 border-b-2").should eq "border-y-2 border-l-3 border-b-2"
      end

      it "handles important" do
        TestTailwindMerger.merge("!bg-red bg-white text-green text-black").should eq "!bg-red text-black"
        TestTailwindMerger.merge("!bg-red bg-white !bg-green bg-black").should eq "!bg-green"
      end

      it "handles important when replacing groups" do
        TestTailwindMerger.merge("border-l-1 border-x-2 border-3").should eq "border-3"
        TestTailwindMerger.merge("!border-l-1 border-x-2 border-3").should eq "!border-l-1 border-3"
        TestTailwindMerger.merge("border-3 !border-l-2 border-l-1").should eq "border-3 !border-l-2"
        TestTailwindMerger.merge("border-3 !border-l-2 border-y-3 !border-x-2").should eq "border-3 border-y-3 !border-x-2"
        TestTailwindMerger.merge("border-3 !border-l-2 border-y-3 !border-x-2 !border-2").should eq "!border-2"
      end

      it "handles scopes (even if they are not specified in that same order)" do
        TestTailwindMerger.merge("hover:bg-red bg-white hover:bg-green").should eq "bg-white hover:bg-green"
        TestTailwindMerger.merge("lg:hover:bg-red hover:md:bg-green hover:lg:bg-blue md:hover:bg-white").should eq "hover:lg:bg-blue md:hover:bg-white"
      end

      it "handles important with scopes" do
        TestTailwindMerger.merge("!hover:bg-red bg-white hover:bg-green").should eq "!hover:bg-red bg-white"
        TestTailwindMerger.merge("lg:hover:bg-red !hover:md:bg-green hover:lg:bg-blue md:hover:bg-white").should eq "!hover:md:bg-green hover:lg:bg-blue"
      end

      it "handles scopes with replacements" do
        TestTailwindMerger.merge("md:border-l-1 md:border-x-2 border-3").should eq "md:border-x-2 border-3"
      end
    end
  end
end
