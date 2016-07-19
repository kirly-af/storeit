import * as fs from 'fs'
import * as api from '../lib/protocol-objects.js'
import userFile from './user-file.js'
import {logger} from '../lib/log.js'

const createTree = (fullPath, ipfs) => {

  return new Promise((resolve, reject) => {

    fs.stat(fullPath, (err, stat) => {

      if (err)
        return reject(err)

      const fullPathStoreDir = userFile.fullPathStoreDir
      const relativePath = fullPath.substr(fullPathStoreDir.length)

      const makeObj = (IPFSHash /* , files */) => {

        const fObj = new api.FileObj(relativePath, IPFSHash /*, files */)
        resolve(fObj)
      }

      if (stat.isDirectory()) {
        /*
        return fs.readdir(fullPath, (err, res) => {
        if (err)
        return reject(err)
        return makeObj(null, res)
      })
      */
        return makeObj(/* null, res */)
      }

      ipfs.addRelative(relativePath)
        .then((hash) => makeObj(hash[0].Hash))
        .catch((err) => reject(err))
    })
  })
}

export default {
  createTree
}
