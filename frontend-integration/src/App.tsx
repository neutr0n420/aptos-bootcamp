import './App.css'

function App() {

  return (
    <>
      <div className='flex justify-between items-center px-12 py-6'>
        <h1 className='text-xl'>Write Transaction</h1>
        <button className='border px-4 py-2 rounded hover:bg-black hover:text-white border-black'>Connect Wallet</button>
      </div>
      <hr />
      <div className='flex flex-col justify-center my-16 mx-[300px] outline outline-gray-800 px-28 py-8'>
        <div className=' flex flex-col   rounded-lg  text-left'>
          <label htmlFor="" className=''>Write your message</label>
          <textarea name="" id="" cols="60" rows="15" className='border rounded px-4'></textarea>
        </div>
        <div>
          <button className='border px-4 py-2 my-6 rounded hover:bg-black hover:text-white border-black '>Submit Message</button>
        </div>
      </div>
    </>
  )
}

export default App
