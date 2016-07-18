import * as fs from 'fs'
import * as path from 'path'

let storeDir = './storeit'

let makeFullPath = (filePath) => path.join(storeDir, filePath)

let dirCreate = (dirPath) => new Promise((resolve, reject) =>
  fs.mkdir(makeFullPath(dirPath), (err) => !err || err.code === 'EEXIST' ?
    resolve({path: dirPath, isDir: true}) : reject(err)
  )
)

let fileCreate = (filePath, data) => new Promise((resolve, reject) =>
  fs.writeFile(makeFullPath(filePath), data, (err) => !err ?
    resolve({path: filePath, data}) : reject(err)
  )
)

let fileDelete = (filePath) => new Promise((resolve, reject) =>
  fs.unlink(makeFullPath(filePath), (err) => !err ?
    resolve({path: filePath}) : reject(err)
  )
)


let fileMove = (src, dst) => new Promise((resolve, reject) =>
  fs.rename(makeFullPath(src), makeFullPath(dst), (err) => !err ?
    resolve({src, dst}) : reject(err)
  )
)

export default {
  setStoreDir(dirPath) {
    storeDir = dirPath
  },
  getStoreDir() {
    return storeDir
  },
  fullPath: makeFullPath,
  dirCreate,
  create: fileCreate,
  del: fileDelete,
  move: fileMove
}

// const readmeHash = 'Qmco5NmRNMit3V2u3whKmMAFaH4tVX4jPnkwZFRdsb4dtT'
// export let storeDir = './storeit'
// export let home = // TODO: get this from server response to JOIN instead
//   api.makeFileObj('/', null, {
//     'readme.txt': api.makeFileObj('/readme.txt', readmeHash)
//   })
//
// let makeInfo = (path, kind) => {
//   return {
//     path,
//     metadata: 'uninplemented for now',
//     contentHash: 'hache',
//     kind,
//     files: []
//   }
// }
//
// let dirToJson = (filename) => {
//
//   let stats = fs.lstatSync(filename)
//
//   let info = makeInfo(filename, stats.isDirectory ? 0 : 1)
//
//   if (stats.isDirectory()) {
//     info.files = fs.readdirSync(filename).map((child) => {
//       return dirToJson(filename + '/' + child)
//     })
//   }
//
//   return info
// }
//
// let mkdirUser = () => {
//   fs.mkdir(storeDir, (err) => {
//     if (err) {
//       logger.warn('cannot mkdir user dir')
//     }
//   })
// }
//
// let makeUserTree = () => {
//   mkdirUser()
//   let dir = dirToJson(storeDir)
//   dir.path = '/'
//   return dir
// }
