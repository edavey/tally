module Tally
  module Tallyable
    
    def self.included base
      base.extend ClassMethods
    end
    
    module ClassMethods
      def has_tally      
        include InstanceMethods
        has_many :votes, :as => :tallyable, :class_name => "TallySheet"
        has_many :votes_for, :as => :tallyable, :class_name => "TallySheet", :conditions => {:for => true}
        has_many :votes_against, :as => :tallyable, :class_name => "TallySheet", :conditions => {:for => false}
      end
    end

    module InstanceMethods
      
      def voted_by? voter
        # TODO: Figure out why I can't do :voter => voter
        !!votes.find(:first, :conditions => {:voter_id => voter, :voter_type => voter.class.to_s})
      end
            
      def update_tally_score!
        update_attribute(:tally_score, tally_ci_lower_bound) # Skips validation
      end
      
      # From http://www.evanmiller.org/how-not-to-sort-by-average-rating.html
      def tally_ci_lower_bound(pos = votes_for.count, n = votes.count, power = 0.10)       
        return tally_score - 0.1 if the_only_votes_are_negative?       
        return 0 if n == 0

        z = ::Rubystats::NormalDistribution.new.icdf(1-power/2)
        phat = 1.0*pos/n
        (phat + z*z/(2*n) - z * Math.sqrt((phat*(1-phat)+z*z/(4*n))/n))/(1+z*z/n)
      end   
      
      private
      
      def the_only_votes_are_negative?
        !votes.empty? && votes_for.empty? && !votes.last.for  
      end    
      
    end
  end
end

# Set it all up.
if Object.const_defined?("ActiveRecord")
  ActiveRecord::Base.send(:include, Tally::Tallyable)
end
