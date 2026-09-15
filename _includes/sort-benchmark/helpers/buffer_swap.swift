extension UnsafeMutableBufferPointer where Element == Int {
    func swapAt(_ i: Int, _ j: Int) {
        let t = self[i]; self[i] = self[j]; self[j] = t
    }
}
