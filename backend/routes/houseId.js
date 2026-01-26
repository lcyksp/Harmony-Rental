// backend/utils/houseId.js
import { pinyin } from 'pinyin-pro'
import crypto from 'crypto'

function pad2(n) {
  return n < 10 ? `0${n}` : String(n)
}

function ymd8(d) {
  return `${d.getFullYear()}${pad2(d.getMonth() + 1)}${pad2(d.getDate())}`
}

function ymdhms14(d) {
  return `${ymd8(d)}${pad2(d.getHours())}${pad2(d.getMinutes())}${pad2(d.getSeconds())}`
}

/** 取城市拼音首字母（2位） */
export function cityAbbr(cityName) {
  const name = String(cityName || '').trim().replace(/市$/g, '')
  if (!name) return 'CS' // 兜底

  // pattern:first => 每个字取首字母；例如 北京 => b j
  const first = pinyin(name, { pattern: 'first', toneType: 'none' })
    .replace(/\s+/g, '')
    .toUpperCase()

  // 保证 2 位：不足补 X，超出截断
  return (first + 'XX').slice(0, 2)
}

/** 生成随机数字串 */
function randomDigits(len) {
  let s = ''
  for (let i = 0; i < len; i++) s += String(crypto.randomInt(0, 10))
  return s
}

/**
 * 生成房源ID：
 * - 优先：AB + YYYYMMDDHHmmss + 随机
 * - 不够长：AB + YYYYMMDD + 随机
 *
 * @param {string} cityName 城市名（北京/广州市/东莞市）
 * @param {number} maxLen   最大长度（按你 DB id 字段长度来）
 * @param {number} minRand  随机后缀最小长度（建议 4 或 6）
 */
export function makeHouseId(cityName, maxLen = 24, minRand = 6) {
  const prefix = cityAbbr(cityName)
  const now = new Date()

  const dt14 = ymdhms14(now)
  const d8 = ymd8(now)

  // 方案1：带时间
  let base = prefix + dt14
  let remain = maxLen - base.length

  // 长度不够，切换到只年月日
  if (remain < minRand) {
    base = prefix + d8
    remain = maxLen - base.length
  }

  // 如果 remain 还是太小，就尽量塞；至少 2 位随机
  let randLen = remain >= minRand ? Math.min(8, remain) : Math.max(2, remain)
  if (randLen <= 0) randLen = 2

  // 最后再兜底：如果 base 本身就超过 maxLen，则截断 base 给随机留 2 位
  if (base.length + randLen > maxLen) {
    const keep = Math.max(0, maxLen - randLen)
    base = base.slice(0, keep)
  }

  return base + randomDigits(randLen)
}
