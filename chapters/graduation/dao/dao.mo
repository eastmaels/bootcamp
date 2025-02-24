import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Text "mo:base/Text";
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
        // let ledger = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);
        let members = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash);

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
                let result = await faucetCanister.mint(caller, 10);
                // ledger.put(caller, 10);
                members.put(caller, member);
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

        // Get the member with the given principal
        // Returns an error if the member does not exist
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
                return #err("Not implemented");
        };

        // Create a new proposal and returns its id
        // Returns an error if the caller is not a mentor or doesn't own at least 1 MBC token
        public shared ({ caller }) func createProposal(content : ProposalContent) : async Result<ProposalId, Text> {
                return #err("Not implemented");
        };

        // Get the proposal with the given id
        // Returns an error if the proposal does not exist
        public query func getProposal(id : ProposalId) : async Result<Proposal, Text> {
                return #err("Not implemented");
        };

        // Returns all the proposals
        public query func getAllProposal() : async [Proposal] {
                return [];
        };

        // Vote for the given proposal
        // Returns an error if the proposal does not exist or the member is not allowed to vote
        public shared ({ caller }) func voteProposal(proposalId : ProposalId, yesOrNo : Bool) : async Result<(), Text> {
                return #err("Not implemented");
        };

        // Returns the Principal ID of the Webpage canister associated with this DAO canister
        public query func getIdWebpage() : async Principal {
                return canisterIdWebpage;
        };

};
