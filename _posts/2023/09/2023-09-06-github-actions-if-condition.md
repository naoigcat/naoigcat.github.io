---
layout: post
title:  GitHub Actionsの実行条件でコンテキストを参照する
date:   2023/09/06 22:57:14 +0900
tags:   github
---

## [ワークフロー内でアクセスできるコンテキストは決まっている](https://docs.github.com/en/actions/learn-github-actions/contexts#context-availability)

|Workflow key                                          |Context                                                                        |
|:-----------------------------------------------------|:------------------------------------------------------------------------------|
|run-name                                              |github, inputs, vars                                                           |
|concurrency                                           |github, inputs, vars                                                           |
|env                                                   |github, secrets, inputs, vars                                                  |
|jobs.\<job_id\>.concurrency                           |github, needs, strategy, matrix, inputs, vars                                  |
|jobs.\<job_id\>.container                             |github, needs, strategy, matrix, vars, inputs                                  |
|jobs.\<job_id\>.container.credentials                 |github, needs, strategy, matrix, env, vars, secrets, inputs                    |
|jobs.\<job_id\>.container.env.\<env_id\>              |github, needs, strategy, matrix, job, runner, env, vars, secrets, inputs       |
|jobs.\<job_id\>.container.image                       |github, needs, strategy, matrix, vars, inputs                                  |
|jobs.\<job_id\>.continue-on-error                     |github, needs, strategy, vars, matrix, inputs                                  |
|jobs.\<job_id\>.defaults.run                          |github, needs, strategy, matrix, env, vars, inputs                             |
|jobs.\<job_id\>.env                                   |github, needs, strategy, matrix, vars, secrets, inputs                         |
|jobs.\<job_id\>.environment                           |github, needs, strategy, matrix, vars, inputs                                  |
|jobs.\<job_id\>.environment.url                       |github, needs, strategy, matrix, job, runner, env, vars, steps, inputs         |
|jobs.\<job_id\>.if                                    |github, needs, vars, inputs                                                    |
|jobs.\<job_id\>.name                                  |github, needs, strategy, matrix, vars, inputs                                  |
|jobs.\<job_id\>.outputs.\<output_id\>                 |github, needs, strategy, matrix, job, runner, env, vars, secrets, steps, inputs|
|jobs.\<job_id\>.runs-on                               |github, needs, strategy, matrix, vars, inputs                                  |
|jobs.\<job_id\>.secrets.\<secrets_id\>                |github, needs, strategy, matrix, secrets, inputs, vars                         |
|jobs.\<job_id\>.services                              |github, needs, strategy, matrix, vars, inputs                                  |
|jobs.\<job_id\>.services.\<service_id\>.credentials   |github, needs, strategy, matrix, env, vars, secrets, inputs                    |
|jobs.\<job_id\>.services.\<service_id\>.env.\<env_id\>|github, needs, strategy, matrix, job, runner, env, vars, secrets, inputs       |
|jobs.\<job_id\>.steps.continue-on-error               |github, needs, strategy, matrix, job, runner, env, vars, secrets, steps, inputs|
|jobs.\<job_id\>.steps.env                             |github, needs, strategy, matrix, job, runner, env, vars, secrets, steps, inputs|
|jobs.\<job_id\>.steps.if                              |github, needs, strategy, matrix, job, runner, env, vars, steps, inputs         |
|jobs.\<job_id\>.steps.name                            |github, needs, strategy, matrix, job, runner, env, vars, secrets, steps, inputs|
|jobs.\<job_id\>.steps.run                             |github, needs, strategy, matrix, job, runner, env, vars, secrets, steps, inputs|
|jobs.\<job_id\>.steps.timeout-minutes                 |github, needs, strategy, matrix, job, runner, env, vars, secrets, steps, inputs|
|jobs.\<job_id\>.steps.with                            |github, needs, strategy, matrix, job, runner, env, vars, secrets, steps, inputs|
|jobs.\<job_id\>.steps.working-directory               |github, needs, strategy, matrix, job, runner, env, vars, secrets, steps, inputs|
|jobs.\<job_id\>.strategy                              |github, needs, vars, inputs                                                    |
|jobs.\<job_id\>.timeout-minutes                       |github, needs, strategy, matrix, vars, inputs                                  |
|jobs.\<job_id\>.with.\<with_id\>                      |github, needs, strategy, matrix, inputs, vars                                  |
|on.workflow_call.inputs.\<inputs_id\>.default         |github, inputs, vars                                                           |
|on.workflow_call.outputs.\<output_id\>.value          |github, jobs, vars, inputs                                                     |

## ステップ内の実行条件でシークレットを参照した場合

`steps`内の`if`条件 (`jobs.<job_id>.steps.if`) で`secrets`を参照した場合、

```yml
name: Test
on:
  push:
    branches:
      - 'test'
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Echo
        if: secrets.TEST != ''
        run: echo test
```

ワークフローの解析時にエラーになる。

```txt
The workflow is not valid. .github/workflows/test.yml (Line: 14, Col: 13): Unrecognized named-value: 'secrets'.
Located at position 1 within expression: secrets.TEST != ''
```

## ステップ内の実行条件で環境変数を参照した場合

`steps`内の`env`で`secrets`を参照した変数を定義して`if`条件では`env`を参照した場合、

```yml
name: Test
on:
  push:
    branches:
      - 'test'
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Echo
        env:
          test: ${{ secrets.TEST }}
        if: env.test != ''
        run: echo test
```

シークレットに`TEST`が定義されていないとジョブは作成されるがステップは実行されない。

## ジョブ内の実行条件でリポジトリ変数を参照した場合

`jobs`内の`if`条件 (`jobs.<job_id>.if`) で`vars`を参照した場合、

```yml
name: Test
on:
  push:
    branches:
      - 'test'
jobs:
  test:
    runs-on: ubuntu-latest
    if: vars.TEST != ''
    steps:
      - name: Echo
        run: echo test
```

リポジトリ変数`TEST`が定義されていないとジョブは実行されない（Skippedで作成はされる）。
