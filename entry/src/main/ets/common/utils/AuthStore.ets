// entry/src/main/ets/common/utils/AuthStore.ets
export class AuthStore {
  // 目前用来模拟“已注册用户的手机号”
  private static registeredPhones: string[] = []

  // 注册：把手机号存进模拟列表
  static registerPhone(phone: string) {
    if (!AuthStore.registeredPhones.includes(phone)) {
      AuthStore.registeredPhones.push(phone)
    }
  }

  // 注销：把手机号从列表中移除（可选）
  static unregisterPhone(phone: string) {
    AuthStore.registeredPhones = AuthStore.registeredPhones.filter(p => p !== phone)
  }

  // 判断是否已注册
  static isRegistered(phone: string): boolean {
    return AuthStore.registeredPhones.includes(phone)
  }
}
