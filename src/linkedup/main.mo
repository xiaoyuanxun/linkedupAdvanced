// Make the Connectd app's public methods available locally
import Connectd "canister:connectd";
import Database "./database";
import Types "./types";
import Utils "./utils";

actor LinkedUp {
  var directory: Database.Directory = Database.Directory();
  let postDirectory: Database.PostDirectory = Database.PostDirectory();
  
  type Time = Types.Time;
  type NewProfile = Types.NewProfile;
  type Profile = Types.Profile;
  type UserId = Types.UserId;

  // Healthcheck

  public func healthcheck(): async Bool { true };

  // Profiles

  public shared(msg) func create(profile: NewProfile): async () {
    directory.createOne(msg.caller, profile);
  };

  public shared(msg) func update(profile: Profile): async () {
    if(Utils.hasAccess(msg.caller, profile)) {
      directory.updateOne(profile.id, profile);
    };
  };

  public query func get(userId: UserId): async Profile {
    Utils.getProfile(directory, userId)
  };

  public query func search(term: Text): async [Profile] {
    directory.findBy(term)
  };

  // Connections

  public shared(msg) func connect(userId: UserId): async () {
    // Call Connectd's public methods without an API
    await Connectd.connect(msg.caller, userId);
  };

  public func getConnections(userId: UserId): async [Profile] {
    let userIds = await Connectd.getConnections(userId);
    directory.findMany(userIds)
  };

  public shared(msg) func isConnected(userId: UserId): async Bool {
    let userIds = await Connectd.getConnections(msg.caller);
    Utils.includes(userId, userIds)
  };

  // Post

  public shared({caller}) func createPost(title: Text, content: Text, time: Time): async () {
    postDirectory.createPost(caller, title, content, time);
  };

  public shared({caller}) func deletePost(index: Nat): async () {
    postDirectory.deletePost(caller, index);
  };

  public shared({caller}) func createComment(postId: Nat, content: Text, createdAt: Time): async () {
    postDirectory.createComment(caller, postId, content, createdAt);
  };

  public shared({caller}) func deleteComment(postId: Nat, commentIndex: Nat): async () {
    postDirectory.deleteComment(caller, postId, commentIndex);
  };

  public shared({caller}) func createLike(postId: Nat, createdAt: Time): async () {
    postDirectory.createLike(caller, postId, createdAt);
  };

  public shared({caller}) func deleteLike(postId: Nat, likeIndex: Nat) {
    postDirectory.deleteLike(caller, postId, likeIndex);
  };

  // User Auth

  public shared query(msg) func getOwnId(): async UserId { msg.caller }
  


};
