import AppState
import CommonModels
import HyperTrackHelper
import SwiftUI
import Utility

struct AuthView: View {
  /// Rider data store
  @ObservedObject var store: Store<AppState, ViewName>
  /// Variable for storing name
  @State var name: String = ""
  /// Variable for storing phone
  @State var phone: String = ""

  var body: some View {
    GeometryReader { geometry in
      VStack(alignment: .leading) {
        /// Name stack
        self.nameStack()
          .padding(.bottom, 10)
        /// Mobile phone stack
        self.phoneNumberStack()
          .padding(.bottom, 10)
        /// Next Button
        Button(action: {
          self.makeNewUser()
        }) {
          Text("Next")
            .modifier(ButtonText())
        }
        .background(self.isValid ? Color.black : Color.gray)
        .cornerRadius(4)
        .disabled(!self.isValid)
        .padding(.vertical, 27)
        Spacer()
      }
      .edgesIgnoringSafeArea(.all)
      .padding(.top, 150)
      .padding(.leading, 32)
      .padding(.trailing, 67)
      .frame(width: geometry.size.width, height: geometry.size.height)
      .background(Color(hex: "50E3C2"))
    }
    .edgesIgnoringSafeArea(.all)
    .modifier(HideKeyboard())
  }

  private var isValid: Bool {
    !phone.isEmpty &&
      !name.isEmpty
  }

  /// Phone name UI stack
  private func nameStack() -> some View {
    Group {
      Text("Enter your name:")
        .fontWeight(.semibold)
      TextField("", text: self.$name)
        .textFieldStyle(UberTextFieldStyle())
    }
  }

  /// Phone number UI stack
  private func phoneNumberStack() -> some View {
    Group {
      Text("Enter your mobile number:")
        .fontWeight(.semibold)
      TextField("Phone number", text: self.$phone)
        .keyboardType(.phonePad)
        .textFieldStyle(UberTextFieldStyle())
    }
  }

  /// Make user on Firestore
  private func makeNewUser() {
    let user = User(
      id: nil,
      role: .rider,
      name: name,
      phone_number: phone,
      device_id: nil,
      car: nil
    )
    setNewFirestoreUser(db, user) { result in
      switch result {
        case let .success(user):
          self.store.value.user = user
          self.store.update(.permissions)
        case let .failure(error):
          print("An error occurred: \(error)")
      }
    }
  }
}
