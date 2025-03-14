import gleam/erlang/process.{type Selector, type Subject}
import gleam/function
import gleam/io
import gleam/otp/actor.{type Started}
import gleam/string

pub const my_name = "worker"

type State {
  State(subject: Subject(WorkerMessage), selector: Selector(WorkerMessage))
}

pub type WorkerMessage =
  #(Subject(String), String)

pub fn start_link(
  name: process.Name(WorkerMessage),
  subject: Subject(WorkerMessage),
) -> Result(process.Pid, a) {
  let selector =
    process.new_selector() |> process.selecting(subject, function.identity)
  let state = State(subject, selector)
  let initialiser =
    actor.initialised(state)
    |> actor.selecting(selector)
    |> actor.returning(subject)

  let assert Ok(actor.Started(pid, _data)) =
    actor.new_with_initialiser(1000, fn() { Ok(initialiser) })
    |> actor.on_message(loop)
    |> actor.start()

  let _ = process.register(pid, name)
  Ok(pid)
}

fn loop(state, msg) {
  case msg {
    #(sender_subject, request) -> {
      case request {
        "die" -> {
          let assert True = False
          io.println("not reached")
        }
        _ -> {
          let reply =
            "Continuing with Worker "
            <> string.inspect(process.self())
            <> " "
            <> request
          process.send(sender_subject, reply)
          io.println(reply)
        }
      }
    }
  }
  actor.continue(state)
}
