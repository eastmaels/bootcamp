import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Map "mo:map/Map";
import { phash } "mo:map/Map";
import Nat "mo:base/Nat";
import Types "types";
actor {

        type Result<A, B> = Result.Result<A, B>;
        type Member = Types.Member;
        type ProposalContent = Types.ProposalContent;
        type ProposalId = Types.ProposalId;
        type Proposal = Types.Proposal;
        type Vote = Types.Vote;
        type HttpRequest = Types.HttpRequest;
        type HttpResponse = Types.HttpResponse;

        // The principal of the Webpage canister associated with this DAO canister (needs to be updated with the ID of your Webpage canister)
        stable let canisterIdWebpage : Principal = Principal.fromText("75i2c-tiaaa-aaaab-qacxa-cai");
        stable var manifesto = "Empower Open Source Contributors";
        stable let name = "Blurtopian";

        let goals = Buffer.Buffer<Text>(0);
        goals.add("Empower Open Source Contributors");
        goals.add("Incentivice Open Source Contributions");
        goals.add("Encourage Open Source Contributions");


        // let ledger = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);
        let members = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash);
        let proposals = HashMap.HashMap<ProposalId, Proposal>(0, Nat.equal, Hash.hash);

        let faucetCanister : actor {
            mint : shared (owner : Principal, amount : Nat) -> async Result<(), Text>;
            burn : shared (owner : Principal, amount : Nat) -> async Result<(), Text>;
            balanceOf : shared query (owner : Principal) -> async Nat;
        } = actor("jaamb-mqaaa-aaaaj-qa3ka-cai");

        public shared query func getName() : async Text {
            return name;
        };

        public shared query func getManifesto() : async Text {
            return manifesto;
        };

        public func setManifesto(newManifesto : Text) : async () {
            manifesto := newManifesto;
            return;
        };

        // Register a new member in the DAO with the given name and principal of the caller
        // Airdrop 10 MBC tokens to the new member
        // New members are always Student
        // Returns an error if the member already exists
        public shared ({ caller }) func registerMember(member : Member) : async Result<(), Text> {
          switch (members.get(caller)) {
            case (null) {
                members.put(caller, member);
                let result = await faucetCanister.mint(caller, 10);
                return #ok();
            };
            case (?member) {
                return #err("Member already exists");
            };
          };
        };

        public query func getAllMembers() : async [Member] {
            return Iter.toArray(members.vals());
        };

        public query func getAllEntries() : async [(Principal, Member)] {
            return Iter.toArray(members.entries());
        };

        public query ({ caller }) func getCaller() : async Principal {
            return caller;
        };

        // Get the member with the given principal
        // Returns an error if the member does not exist
        public query func getMember(p : Principal) : async Result<Member, Text> {
          switch (members.get(p)) {
            case (null) {
                return #err("Member does not exist");
            };
            case (?member) {
                return #ok(member);
            };
          };
        };

        public func getMemberBalance(p : Principal) : async Result<Nat, Text> {
          switch (members.get(p)) {
            case (null) {
                return #err("Member does not exist");
            };
            case (?member) {
              let result = await faucetCanister.balanceOf(p);
              return #ok(result);
            };
          };
        };


        // Graduate the student with the given principal
        // Returns an error if the student does not exist or is not a student
        // Returns an error if the caller is not a mentor
        public shared ({ caller }) func graduate(student : Principal) : async Result<(), Text> {
          switch (members.get(caller)) {
            case (null) {
              return #err("Caller is not a member");
            };
            case (? callerRecord) {
              if (callerRecord.role != #Mentor) {
                return #err("Caller is not a mentor");
              };
            };
          };

          switch (members.get(student)) {
            case (null) {
                return #err("Member does not exist");
            };
            case (? studentRecord) {
              if (studentRecord.role != #Student) {
                return #err("Member is not a student");
              };

              let updateMember = { name = studentRecord.name; role = #Graduate; };
              members.put(student, updateMember);
              return #ok();
            };
          };
        };

        // Create a new proposal and returns its id
        // Returns an error if the caller is not a mentor or doesn't own at least 1 MBC token
        public shared ({ caller }) func createProposal(content : ProposalContent) : async Result<ProposalId, Text> {
          switch (members.get(caller)) {
            case (null) {
              return #err("Caller is not a member");
            };
            case (? callerRecord) {
              if (callerRecord.role != #Mentor) {
                return #err("Caller is not a mentor");
              };
            };
          };

          let result = await faucetCanister.balanceOf(caller);
          if (result < 1) {
            return #err("Caller does not have enough MBC tokens");
          };

          let _burnResult = await faucetCanister.burn(caller, 1);

          let proposalId = proposals.size();
          let proposal = {
            id = proposalId;
            content = content;
            creator = caller;
            created = Time.now();
            executed = null;
            votes = [];
            voteScore = 0;
            status = #Open;
          };
          proposals.put(proposalId, proposal);
          return #ok(proposalId);
        };

        // Get the proposal with the given id
        // Returns an error if the proposal does not exist
        public query func getProposal(id : ProposalId) : async Result<Proposal, Text> {
          switch (proposals.get(id)) {
            case (null) {
                return #err("Proposal does not exist");
            };
            case (? proposal) {
                return #ok(proposal);
            };
          };
        };

        // Returns all the proposals
        public query func getAllProposal() : async [Proposal] {
          return Iter.toArray(proposals.vals());
        };

        public query func getAllProposalEntries() : async [(ProposalId, Proposal)] {
            return Iter.toArray(proposals.entries());
        };

        // Vote for the given proposal
        // Returns an error if the proposal does not exist or the member is not allowed to vote
        public shared ({ caller }) func voteProposal(proposalId : ProposalId, yesOrNo : Bool) : async Result<(), Text> {

          var voteMultiplier = 1;
          switch (members.get(caller)) {
            case (null) {
              return #err("Caller is not a member");
            };
            case (? callerRecord) {
              if (callerRecord.role == #Student) {
                return #err("Caller is not allowed to vote");
              };

              if (callerRecord.role == #Mentor) {
                voteMultiplier := 5;
              };
            };
          };

          switch (proposals.get(proposalId)) {
            case (null) {
                return #err("Proposal does not exist");
            };
            case (? proposal) {
                // Check if the proposal is open for voting
                if (proposal.status != #Open) {
                    return #err("The proposal is not open for voting");
                };
                // Check if the caller has already voted
                if (_hasVoted(proposal, caller)) {
                    return #err("The caller has already voted on this proposal");
                };


                let balance = await faucetCanister.balanceOf(caller);
                let votingPower = (voteMultiplier * balance);
                let vote = { member = caller; votingPower = votingPower; yesOrNo = yesOrNo; };

                let newVoteScore = proposal.voteScore + votingPower;
                var newExecuted : ?Time.Time = null;
                let newVotes = Buffer.fromArray<Vote>(proposal.votes);
                let newStatus = if (newVoteScore >= 100) {
                    #Accepted;
                } else if (newVoteScore <= -100) {
                    #Rejected;
                } else {
                    #Open;
                };
                switch (newStatus) {
                    case (#Accepted) {
                        _executeProposal(proposal.content);
                        newExecuted := ?Time.now();
                    };
                    case (_) {};
                };
                let newProposal : Proposal = {
                    id = proposal.id;
                    content = proposal.content;
                    creator = proposal.creator;
                    created = proposal.created;
                    executed = newExecuted;
                    votes = Buffer.toArray(newVotes);
                    voteScore = newVoteScore;
                    status = newStatus;
                };
                proposals.put(proposal.id, newProposal);

                return #ok();
            };
          };
        };

        func _executeProposal(content : ProposalContent) : () {
            switch (content) {
                case (#ChangeManifesto(newManifesto)) {
                  manifesto := newManifesto;
                };
                case (#AddGoal(newGoal)) {
                  goals.add(newGoal);
                };
                case (#AddMentor(principal)) {
                  switch(members.get(principal)) {
                    case (null) {
                      return;
                    };
                    case (? principal) {
                      let updateMember = { name = principal.name; role = #Mentor; };
                      members.put(principal, updateMember);
                };
            };
            return;
        };



        func _hasVoted(proposal : Proposal, member : Principal) : Bool {
          return Array.find<Vote>(
            proposal.votes,
            func(vote : Vote) {
                return vote.member == member;
            },
          ) != null;
        };

        // Returns the Principal ID of the Webpage canister associated with this DAO canister
        public query func getIdWebpage() : async Principal {
          return canisterIdWebpage;
        };

};
