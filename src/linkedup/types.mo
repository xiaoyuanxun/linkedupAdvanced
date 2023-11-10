import Principal "mo:base/Principal";
import Time "mo:base/Time";

module {
  public type UserId = Principal;
  public type Time = Time.Time;

  public type NewProfile = {
    firstName: Text;
    lastName: Text;
    title: Text;
    company: Text;
    experience: Text;
    education: Text;
    imgUrl: Text;
  };

  public type Profile = {
    id: UserId;
    firstName: Text;
    lastName: Text;
    title: Text;
    company: Text;
    experience: Text;
    education: Text;
    imgUrl: Text;
  };
  
  public type Post = {
    id: Nat; // Post Index ID
    userId: UserId;
    title: Text;
    content: Text;
    var likeNumber: Nat;
    var commentNumber: Nat;
    createdAt: Time;
  };

  public type Comment = {
    id: Nat; // Comment Index ID
    postId: Nat; // Post Index ID
    userId: UserId;
    content: Text;
    createdAt: Time;
  };

  public type Like = {
    id: Nat; // Like Index ID
    postId: Nat;
    userId: UserId;
    createdAt: Time;
  }

};
