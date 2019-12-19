import AppState
import CommonModels
import SwiftUI
import Utility

public struct LoginView: View {
  /// User data store
  @ObservedObject public var store: Store<AppState, ViewName>

  public init(store: Store<AppState, ViewName>) {
    self.store = store
  }

  public var body: some View {
    VStack {
      HStack {
        Image("logo")
        VStack(alignment: .leading) {
          Text("HyperTrack")
            .font(.system(size: 12))
            .fontWeight(.semibold)
          Text("Ridesharing")
            .font(.system(size: 26))
            .fontWeight(.semibold)
        }.foregroundColor(.white)
      }
      .padding(.top, 119)
      Spacer()
      Button(action: {
        self.store.update(.auth)
      }) {
        Text("LOGIN")
          .modifier(ButtonText())
      }
      .background(Color.black)
      .cornerRadius(4)
      .padding(.bottom, 55)
    }
    .background(
      Image("background")
        .resizable()
        .scaledToFill()
    )
    .edgesIgnoringSafeArea(.all)
  }
}
