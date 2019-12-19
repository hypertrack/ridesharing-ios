import AppState
import CommonModels
import HyperTrack
import HyperTrackHelper
import SwiftUI
import Utility

struct AuthView: View {
  /// HyperTrack SDK Instance
  let hypertrack: HyperTrack
  @ObservedObject var store: Store<AppState, ViewName>

  /// Driver's name
  @State var name: String = ""
  /// Driver's car model
  @State var carModel: String = ""
  /// Driver's license plate
  @State var carPlate: String = ""
  /// Driver's phone number
  @State var phone: String = ""

  var body: some View {
    GeometryReader { geometry in
      VStack(alignment: .leading) {
        /// Name stack
        self.nameStack()
          .padding(.bottom, 10)
        /// Car detail stack
        self.carDetailsStack()
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
      !name.isEmpty &&
      !carModel.isEmpty &&
      !carPlate.isEmpty
  }

  private func nameStack() -> some View {
    Group {
      Text("Enter your name:")
        .fontWeight(.semibold)
      TextField("", text: self.$name)
        .textFieldStyle(RidesharingTextFieldStyle())
    }
  }

  private func carDetailsStack() -> some View {
    Group {
      Text("Enter your car details:")
        .fontWeight(.semibold)
      HStack {
        TextField("Car model", text: self.$carModel)
          .textFieldStyle(RidesharingTextFieldStyle())
        Spacer()
          .frame(width: 20)
        TextField("Car plate", text: self.$carPlate)
          .textFieldStyle(RidesharingTextFieldStyle())
      }
    }
  }

  private func phoneNumberStack() -> some View {
    Group {
      Text("Enter your mobile number:")
        .fontWeight(.semibold)
      TextField("Phone number", text: self.$phone)
        .keyboardType(.phonePad)
        .textFieldStyle(RidesharingTextFieldStyle())
    }
  }

  private func makeNewUser() {
    let user = User(
      id: nil,
      role: .driver,
      name: name,
      phone_number: phone,
      device_id: hypertrack.deviceID,
      car: User.Car(model: carModel, license_plate: carPlate)
    )
    setNewFirestoreUser(db, user) { result in
      switch result {
        case let .success(user):
          self.makeHTUser(user)
          self.store.value.user = user
          self.store.update(.permissions)
        case let .failure(error):
          print("An error occurred: \(error)")
      }
    }
  }

  private func makeHTUser(_ user: User) {
    let id = user.id ?? ""
    let name = user.name
    let phoneNumber = user.phone_number ?? ""
    let carModel = user.car?.model ?? ""
    let carLicensePlate = user.car?.license_plate ?? ""
    let car = ["model": carModel, "license_plate": carLicensePlate]

    hypertrack.setDeviceName(user.name)
    if let metadata = HyperTrack.Metadata(dictionary: [
      "user_id": id,
      "name": name,
      "phone_number": phoneNumber,
      "car": car
    ]) {
      hypertrack.setDeviceMetadata(metadata)
    }
  }
}
