// entry/src/main/ets/store/UserHouseStore.ets
export class UserHouse {
  id: number = 0
  title: string = ''
  price: number = 0
  address: string = ''
  area: number = 0
  cover: string = ''
  isRented: boolean = false
}

let nextId: number = 10000
let userHouses: UserHouse[] = []

export function addUserHouse(
  title: string,
  price: number,
  address: string,
  area: number,
  cover: string
): UserHouse {
  let h = new UserHouse()
  h.id = nextId++
  h.title = title
  h.price = price
  h.address = address
  h.area = area
  h.cover = cover
  h.isRented = false
  userHouses.push(h)
  return h
}

export function getUserHouses(): UserHouse[] {
  return userHouses
}

export function setHouseRented(id: number, rented: boolean): void {
  for (let i = 0; i < userHouses.length; i++) {
    if (userHouses[i].id === id) {
      userHouses[i].isRented = rented
      return
    }
  }
}
