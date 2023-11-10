import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Types "./types";
import TrieMap "mo:base/TrieMap";
import TrieSet "mo:base/TrieSet";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Time "mo:base/Time";

module {
  type NewProfile = Types.NewProfile;
  type Profile = Types.Profile;
  type UserId = Types.UserId;
  type Time = Time.Time;

  public class Directory() {
    // The "database" is just a local hash map
    let hashMap = HashMap.HashMap<UserId, Profile>(1, isEq, Principal.hash);

    public func createOne(userId: UserId, profile: NewProfile) {
      hashMap.put(userId, makeProfile(userId, profile));
    };

    public func updateOne(userId: UserId, profile: Profile) {
      hashMap.put(userId, profile);
    };

    public func findOne(userId: UserId): ?Profile {
      hashMap.get(userId)
    };

    public func findMany(userIds: [UserId]): [Profile] {
      func getProfile(userId: UserId): Profile {
        Option.unwrap<Profile>(hashMap.get(userId))
      };
      Array.map<UserId, Profile>(userIds, getProfile)
    };

    public func findBy(term: Text): [Profile] {
      var profiles: [Profile] = [];
      for ((id, profile) in hashMap.entries()) {
        let fullName = profile.firstName # " " # profile.lastName;
        if (includesText(fullName, term)) {
          profiles := Array.append<Profile>(profiles, [profile]);
        };
      };
      profiles
    };

    // Helpers

    func makeProfile(userId: UserId, profile: NewProfile): Profile {
      {
        id = userId;
        firstName = profile.firstName;
        lastName = profile.lastName;
        title = profile.title;
        company = profile.company;
        experience = profile.experience;
        education = profile.education;
        imgUrl = profile.imgUrl;
      }
    };

    func includesText(string: Text, term: Text): Bool {
      let stringArray = Iter.toArray<Char>(string.chars());
      let termArray = Iter.toArray<Char>(term.chars());

      var i = 0;
      var j = 0;

      while (i < stringArray.size() and j < termArray.size()) {
        if (stringArray[i] == termArray[j]) {
          i += 1;
          j += 1;
          if (j == termArray.size()) { return true; }
        } else {
          i += 1;
          j := 0;
        }
      };
      false
    };
  };

  public class PostDirectory() {
      type UserId = Types.UserId;
      type Post = Types.Post;
      type Comment = Types.Comment;
      type Like = Types.Like;

      var postIndex: Nat = 0;

      let postMap = TrieMap.TrieMap<Principal, TrieMap.TrieMap<Nat, Post>>(Principal.equal, Principal.hash); // user -> user's posts
      let commentMap = TrieMap.TrieMap<Nat, TrieMap.TrieMap<Nat, Comment>>(Nat.equal, Hash.hash); // postId -> post's comments
      let likeMap = TrieMap.TrieMap<Nat, TrieMap.TrieMap<Nat, Like>>(Nat.equal, Hash.hash); // postId -> post's likes user

      // 发帖
      public func createPost(userId: UserId, title: Text, content: Text, time: Time) {
        let post: Post = {
          id = postIndex;
          userId = userId;
          title = title;
          content = content;
          var likeNumber = 0;
          var commentNumber = 0;
          createdAt = time;
        };

        switch(postMap.get(userId)) {
          case(?posts) {
            posts.put(postIndex, post);
            postMap.put(userId, posts);
          };
          case(null) {
            let newPosts = TrieMap.TrieMap<Nat, Post>(Nat.equal, Hash.hash);
            newPosts.put(postIndex, post);
            postMap.put(userId, newPosts);
          };
        };

        postIndex += 1;
      };

      // 删帖
      public func deletePost(userId: UserId, postId: Nat) {
        switch(postMap.get(userId)) {
          case(?posts) {
            // 删帖本身
            posts.delete(postId);
            postMap.put(userId, posts);
            // 删除相关评论
            commentMap.delete(postId);
            // 删除相关点赞
            likeMap.delete(postId);            
          };
          case(null) { assert(false); };
        };
      };

      // 查询某个用户的所有帖子
      public func getUserPosts(userId: UserId): [Post] {
        switch(postMap.get(userId)) {
          case(null) {};
          case(?posts) {
            return Iter.toArray(posts.vals())
          };
        };
        []
      };

      // 评论
      public func createComment(userId: UserId, postId: Nat, content: Text, createdAt: Time) {
        switch(getCommentNumber(userId, postId)) {
          case(?value) {
            let commentNumber = value + 1;
            switch(commentMap.get(postId)) {
              case(?comments) {
                comments.put(commentNumber,{
                  id = commentNumber;
                  postId = postId;
                  userId = userId;
                  content = content;
                  createdAt = createdAt;
                });
              };
              case(null) {
                let newComments = TrieMap.TrieMap<Nat, Comment>(Nat.equal, Hash.hash);
                newComments.put(commentNumber,{
                  id = commentNumber;
                  postId = postId;
                  userId = userId;
                  content = content;
                  createdAt = createdAt;
                });
                commentMap.put(postId, newComments);
              };
            };
            addCommentNumber(userId, postId);
          };
          case(null) { };
        };
      };

      // 删评
      public func deleteComment(userId: UserId, postId: Nat, commentIndex: Nat) {
        switch(commentMap.get(postId)) {
          case(?comments) {
            comments.delete(commentIndex);
            reduceCommentNumber(userId, postId);
          };
          case(null) { };
        }
      };

      // 查询某个帖子的所有评论
      public func getComments(postId: Nat): [Comment] {
        switch(commentMap.get(postId)) {
          case(null) {};
          case(?comments) {
            return Iter.toArray(comments.vals());
          };
        };
        []
      };

      // 点赞
      public func createLike(userId: UserId, postId: Nat, createdAt: Time) {
        switch(getLikeNumber(userId, postId)) {
          case(?value) {
            let likeNumber = value + 1;
            switch(likeMap.get(postId)) {
              case(?likes) {
                likes.put(likeNumber, {
                  id = likeNumber;
                  postId = postId;
                  userId = userId;
                  createdAt = createdAt;
                });
              };
              case(null) {
                let newLikes = TrieMap.TrieMap<Nat, Like>(Nat.equal, Hash.hash);
                newLikes.put(likeNumber, {
                  id = likeNumber;
                  postId = postId;
                  userId = userId;
                  createdAt = createdAt;
                });
              };
            };
            addCommentNumber(userId, postId);
          };
          case(null) { };
        };
      };

      // 取点
      public func deleteLike(userId: UserId, postId: Nat, likeIndex: Nat) {
        switch(likeMap.get(postId)) {
          case(?likes) {
            likes.delete(likeIndex);
            reduceLikeNumber(userId, postId);
          };
          case(null) { };
        };
      };

      // 查询某个帖子的所有点赞信息
      public func getLikes(postId: Nat): [Like] {
        switch(likeMap.get(postId)) {
          case(null) {};
          case(?likes) {
            return Iter.toArray(likes.vals());
          };
        };
        []
      };

      private func getCommentNumber(userId: UserId, index: Nat): ?Nat {
        switch(postMap.get(userId)) {
          case(?posts) {
            switch(posts.get(index)) {
              case(?post) {
                return ?post.commentNumber;
              };
              case(null) { };
            }
          };
          case(null) { };
        };
        null 
      };

      private func addCommentNumber(userId: UserId, index: Nat) {
        switch(postMap.get(userId)) {
          case(?posts) {
            switch(posts.get(index)) {
              case(?post) {
                post.commentNumber += 1;
              };
              case(null) { assert(false); };
            }
          };
          case(null) { assert(false); };
        };
      };

      private func reduceCommentNumber(userId: UserId, index: Nat) {
        switch(postMap.get(userId)) {
          case(?posts) {
            switch(posts.get(index)) {
              case(?post) {
                post.commentNumber -= 1;
              };
              case(null) { assert(false); };
            }
          };
          case(null) { assert(false); };
        };
      };

      private func getLikeNumber(userId: UserId, index: Nat): ?Nat {
        switch(postMap.get(userId)) {
          case(?posts) {
            switch(posts.get(index)) {
              case(?post) {
                return ?post.likeNumber;
              };
              case(null) { };
            };
          };
          case(null) { };
        };
        null
      };

      private func addLikeNumber(userId: UserId, index: Nat) {
        switch(postMap.get(userId)) {
          case(?posts) {
            switch(posts.get(index)) {
              case(?post) {
                post.likeNumber += 1;
              };
              case(null) { };
            };
          };
          case(null) { };
        }
      };

      private func reduceLikeNumber(userId: UserId, index: Nat) {
        switch(postMap.get(userId)) {
          case(?posts) {
            switch(posts.get(index)) {
              case(?post) {
                post.likeNumber -= 1;
              };
              case(null) { };
            };
          };
          case(null) { };
        }
      };
  };

  func isEq(x: UserId, y: UserId): Bool { x == y };
};
